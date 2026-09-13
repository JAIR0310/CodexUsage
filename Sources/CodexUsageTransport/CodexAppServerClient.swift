import CodexUsageCore
import Foundation

public actor CodexAppServerClient {
  enum ClientError: Error, Equatable {
    case codexExecutableNotFound
    case processLaunchFailed
    case processStopped
    case requestTimedOut
    case invalidInitializeResponse
  }

  private let executableURL: URL
  private let requestTimeoutNanoseconds: UInt64
  private var process: Process?
  private var inputHandle: FileHandle?
  private var outputHandle: FileHandle?
  private var receiveBuffer = Data()
  private var pending: [Int: CheckedContinuation<Data, Error>] = [:]
  private var timeoutTasks: [Int: Task<Void, Never>] = [:]
  private var nextID = 1
  private var initialized = false
  private var generation = 0

  public init(
    executableURL: URL,
    requestTimeoutNanoseconds: UInt64 = 8_000_000_000
  ) {
    self.executableURL = executableURL
    self.requestTimeoutNanoseconds = requestTimeoutNanoseconds
  }

  public func fetchRateLimits() async throws -> CodexQuotaSnapshot {
    try await ensureReady()
    let response = try await request(
      method: "account/rateLimits/read",
      params: nil
    )
    return try RateLimitParser.parseRateLimits(from: response)
  }

  public func stop() {
    generation += 1
    initialized = false
    receiveBuffer.removeAll(keepingCapacity: false)

    let child = process
    let input = inputHandle
    let output = outputHandle

    // Stop accepting callbacks from the old generation before teardown starts.
    output?.readabilityHandler = nil
    child?.terminationHandler = nil

    // Closing stdin first gives app-server a chance to observe EOF and exit
    // normally. R4 closed stdin and immediately sent SIGTERM, which was a
    // real race on macOS: the child could be killed before processing EOF.
    input?.closeFile()

    if let child, child.isRunning {
      waitForExit(child, timeout: 0.75)

      if child.isRunning {
        child.terminate()
        waitForExit(child, timeout: 0.50)
      }
    }

    output?.closeFile()

    process = nil
    inputHandle = nil
    outputHandle = nil

    let tasks = timeoutTasks.values
    timeoutTasks.removeAll()
    for task in tasks {
      task.cancel()
    }

    let continuations = pending.values
    pending.removeAll()
    for continuation in continuations {
      continuation.resume(throwing: ClientError.processStopped)
    }
  }

  private func waitForExit(_ child: Process, timeout: TimeInterval) {
    let deadline = Date().addingTimeInterval(timeout)
    while child.isRunning, Date() < deadline {
      Thread.sleep(forTimeInterval: 0.01)
    }
  }

  private func ensureReady() async throws {
    if initialized, process?.isRunning == true {
      return
    }

    if process != nil {
      stop()
    }

    try launch()

    do {
      let initializeResponse = try await request(
        method: "initialize",
        params: [
          "clientInfo": [
            "name": "codex-usage-titanium",
            "title": "Codex Usage",
            "version": "1.0",
          ],
          "capabilities": [
            "experimentalApi": false
          ],
        ]
      )

      struct InitializeResponse: Decodable {
        struct ResultPayload: Decodable {
          let userAgent: String?
        }

        struct RPCError: Decodable {
          let message: String?
        }

        let result: ResultPayload?
        let error: RPCError?
      }

      let decoded = try JSONDecoder().decode(
        InitializeResponse.self,
        from: initializeResponse
      )
      guard decoded.error == nil, decoded.result != nil else {
        throw ClientError.invalidInitializeResponse
      }

      try sendNotification(method: "initialized", params: [:])
      initialized = true
    } catch {
      stop()
      throw error
    }
  }

  private func launch() throws {
    let newGeneration = generation + 1
    generation = newGeneration

    let inputPipe = Pipe()
    let outputPipe = Pipe()
    let child = Process()

    guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
      throw ClientError.codexExecutableNotFound
    }

    child.executableURL = executableURL
    child.arguments = ["app-server", "--stdio"]
    child.standardInput = inputPipe
    child.standardOutput = outputPipe
    child.standardError = FileHandle.nullDevice

    process = child
    inputHandle = inputPipe.fileHandleForWriting
    outputHandle = outputPipe.fileHandleForReading
    receiveBuffer.removeAll(keepingCapacity: true)

    outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
      let data = handle.availableData
      guard !data.isEmpty else { return }
      Task { await self?.consume(data, generation: newGeneration) }
    }

    child.terminationHandler = { [weak self] _ in
      Task { await self?.handleTermination(generation: newGeneration) }
    }

    do {
      try child.run()
    } catch {
      outputPipe.fileHandleForReading.readabilityHandler = nil
      inputPipe.fileHandleForWriting.closeFile()
      outputPipe.fileHandleForReading.closeFile()
      process = nil
      inputHandle = nil
      outputHandle = nil
      throw ClientError.processLaunchFailed
    }
  }

  private func request(
    method: String,
    params: [String: Any]?
  ) async throws -> Data {
    let id = nextID
    nextID += 1

    var object: [String: Any] = [
      "id": id,
      "method": method,
    ]
    if let params {
      object["params"] = params
    }

    let payload = try JSONSerialization.data(withJSONObject: object)
    var framed = payload
    framed.append(0x0A)

    return try await issueRequest(id: id, framed: framed)
  }

  private func issueRequest(id: Int, framed: Data) async throws -> Data {
    guard let inputHandle, process?.isRunning == true else {
      throw ClientError.processStopped
    }

    let timeout = requestTimeoutNanoseconds

    return try await withTaskCancellationHandler(
      operation: {
        try await withCheckedThrowingContinuation { continuation in
          pending[id] = continuation
          timeoutTasks[id] = Task { [weak self] in
            do {
              try await Task.sleep(nanoseconds: timeout)
            } catch {
              return
            }
            await self?.expireRequest(id: id)
          }

          do {
            try inputHandle.write(contentsOf: framed)
          } catch {
            timeoutTasks.removeValue(forKey: id)?.cancel()
            pending.removeValue(forKey: id)
            continuation.resume(throwing: error)
          }
        }
      },
      onCancel: {
        Task { await self.cancelRequest(id: id) }
      })
  }

  private func cancelRequest(id: Int) {
    timeoutTasks.removeValue(forKey: id)?.cancel()
    guard let continuation = pending.removeValue(forKey: id) else { return }
    continuation.resume(throwing: CancellationError())
  }

  private func expireRequest(id: Int) {
    guard let continuation = pending.removeValue(forKey: id) else { return }
    timeoutTasks.removeValue(forKey: id)?.cancel()

    // A timed-out stdio request means this app-server instance is no longer trusted.
    // Restart cleanly on the next 1-second refresh instead of hanging forever.
    stop()
    continuation.resume(throwing: ClientError.requestTimedOut)
  }

  private func sendNotification(method: String, params: [String: Any]) throws {
    guard let inputHandle, process?.isRunning == true else {
      throw ClientError.processStopped
    }

    let object: [String: Any] = [
      "method": method,
      "params": params,
    ]
    var data = try JSONSerialization.data(withJSONObject: object)
    data.append(0x0A)
    try inputHandle.write(contentsOf: data)
  }

  private func consume(_ data: Data, generation incomingGeneration: Int) {
    guard incomingGeneration == generation else { return }
    receiveBuffer.append(data)

    while let newline = receiveBuffer.firstIndex(of: 0x0A) {
      let line = receiveBuffer[..<newline]
      receiveBuffer.removeSubrange(...newline)

      guard !line.isEmpty,
        let object = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
        let number = object["id"] as? NSNumber
      else {
        continue
      }

      let id = number.intValue
      timeoutTasks.removeValue(forKey: id)?.cancel()

      guard let continuation = pending.removeValue(forKey: id) else {
        continue
      }
      continuation.resume(returning: Data(line))
    }
  }

  private func handleTermination(generation incomingGeneration: Int) {
    guard incomingGeneration == generation else { return }

    initialized = false
    outputHandle?.readabilityHandler = nil
    inputHandle?.closeFile()
    outputHandle?.closeFile()
    process?.terminationHandler = nil
    process = nil
    inputHandle = nil
    outputHandle = nil
    receiveBuffer.removeAll(keepingCapacity: false)

    let tasks = timeoutTasks.values
    timeoutTasks.removeAll()
    for task in tasks {
      task.cancel()
    }

    let continuations = pending.values
    pending.removeAll()
    for continuation in continuations {
      continuation.resume(throwing: ClientError.processStopped)
    }
  }
}
