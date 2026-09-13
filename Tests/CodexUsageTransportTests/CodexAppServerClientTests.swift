import Foundation
import XCTest

@testable import CodexUsageTransport

final class CodexAppServerClientTests: XCTestCase {
  func testReadsRateLimitsFromPersistentJSONRPCChildProcess() async throws {
    let temp = FileManager.default.temporaryDirectory
      .appendingPathComponent("codex-usage-fake-\(UUID().uuidString).py")

    let script = #"""
      #!/usr/bin/env python3
      import json
      import sys

      for line in sys.stdin:
          try:
              obj = json.loads(line)
          except Exception:
              continue

          method = obj.get("method")
          req_id = obj.get("id")

          if method == "initialize" and req_id is not None:
              print(json.dumps({
                  "id": req_id,
                  "result": {
                      "userAgent": "fake/1.0",
                      "codexHome": "/tmp/.codex",
                      "platformFamily": "unix",
                      "platformOs": "test",
                      "futureField": {"nested": True}
                  }
              }), flush=True)
          elif method == "account/rateLimits/read" and req_id is not None:
              print(json.dumps({
                  "id": req_id,
                  "result": {
                      "rateLimits": {
                          "primary": {
                              "usedPercent": 12,
                              "windowDurationMins": 300,
                              "resetsAt": 1789069799
                          },
                          "secondary": {
                              "usedPercent": 61,
                              "windowDurationMins": 10080,
                              "resetsAt": 1789447124
                          }
                      }
                  }
              }), flush=True)
      """#

    try script.write(to: temp, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: temp.path
    )
    defer { try? FileManager.default.removeItem(at: temp) }

    let client = CodexAppServerClient(executableURL: temp)
    let first = try await client.fetchRateLimits()

    XCTAssertEqual(first.fiveHour?.remainingPercent, 88)
    XCTAssertEqual(first.weekly?.remainingPercent, 39)

    for _ in 0..<100 {
      let next = try await client.fetchRateLimits()
      XCTAssertEqual(next, first)
    }

    await client.stop()
  }

  func testTimeoutStopsBrokenServerAndNextRefreshCanRecover() async throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("codex-usage-timeout-\(UUID().uuidString)")
    let executable = tempDir.appendingPathComponent("fake-codex.py")
    let marker = tempDir.appendingPathComponent("timed-out-once.marker")

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let markerLiteral = marker.path
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "'", with: "\\'")

    let script = """
      #!/usr/bin/env python3
      import json
      import os
      import sys

      marker = '\(markerLiteral)'

      for line in sys.stdin:
          try:
              obj = json.loads(line)
          except Exception:
              continue

          method = obj.get('method')
          req_id = obj.get('id')

          if method == 'initialize' and req_id is not None:
              print(json.dumps({
                  'id': req_id,
                  'result': {
                      'userAgent': 'fake/1.0',
                      'codexHome': '/tmp/.codex',
                      'platformFamily': 'unix',
                      'platformOs': 'test'
                  }
              }), flush=True)
          elif method == 'account/rateLimits/read' and req_id is not None:
              if not os.path.exists(marker):
                  open(marker, 'w').close()
                  continue

              print(json.dumps({
                  'id': req_id,
                  'result': {
                      'rateLimits': {
                          'primary': {
                              'usedPercent': 20,
                              'windowDurationMins': 300,
                              'resetsAt': 1789069799
                          },
                          'secondary': {
                              'usedPercent': 40,
                              'windowDurationMins': 10080,
                              'resetsAt': 1789447124
                          }
                      }
                  }
              }), flush=True)
      """

    try script.write(to: executable, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: executable.path
    )

    let client = CodexAppServerClient(
      executableURL: executable,
      requestTimeoutNanoseconds: 1_000_000_000
    )

    do {
      _ = try await client.fetchRateLimits()
      XCTFail("Expected first request to time out")
    } catch let error as CodexAppServerClient.ClientError {
      XCTAssertEqual(error, .requestTimedOut)
    }

    let recovered = try await client.fetchRateLimits()
    XCTAssertEqual(recovered.fiveHour?.remainingPercent, 80)
    XCTAssertEqual(recovered.weekly?.remainingPercent, 60)

    await client.stop()
  }

  func testHandlesFragmentedResponsesAndIgnoresNotifications() async throws {
    let temp = FileManager.default.temporaryDirectory
      .appendingPathComponent("codex-usage-fragmented-\(UUID().uuidString).py")

    let script = #"""
      #!/usr/bin/env python3
      import json
      import sys
      import time

      for line in sys.stdin:
          try:
              obj = json.loads(line)
          except Exception:
              continue

          method = obj.get("method")
          req_id = obj.get("id")

          if method == "initialize" and req_id is not None:
              print(json.dumps({
                  "id": req_id,
                  "result": {
                      "userAgent": "fake/1.0"
                  }
              }), flush=True)
          elif method == "account/rateLimits/read" and req_id is not None:
              print(json.dumps({
                  "method": "account/rateLimits/updated",
                  "params": {"rateLimits": []}
              }), flush=True)

              payload = json.dumps({
                  "id": req_id,
                  "result": {
                      "rateLimits": {
                          "primary": {
                              "usedPercent": 33,
                              "windowDurationMins": 300,
                              "resetsAt": 1789069799
                          },
                          "secondary": {
                              "usedPercent": 44,
                              "windowDurationMins": 10080,
                              "resetsAt": 1789447124
                          }
                      }
                  }
              })
              split = len(payload) // 2
              sys.stdout.write(payload[:split])
              sys.stdout.flush()
              time.sleep(0.05)
              sys.stdout.write(payload[split:] + "\n")
              sys.stdout.flush()
      """#

    try script.write(to: temp, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: temp.path
    )
    defer { try? FileManager.default.removeItem(at: temp) }

    let client = CodexAppServerClient(executableURL: temp)
    let snapshot = try await client.fetchRateLimits()

    XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 67)
    XCTAssertEqual(snapshot.weekly?.remainingPercent, 56)

    await client.stop()
  }

  func testRecoversAfterChildProcessTerminatesBetweenRefreshes() async throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("codex-usage-restart-\(UUID().uuidString)")
    let executable = tempDir.appendingPathComponent("fake-codex.py")
    let marker = tempDir.appendingPathComponent("exited-once.marker")

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let markerLiteral = marker.path
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "'", with: "\\'")

    let script = """
      #!/usr/bin/env python3
      import json
      import os
      import sys

      marker = '\(markerLiteral)'

      for line in sys.stdin:
          try:
              obj = json.loads(line)
          except Exception:
              continue

          method = obj.get('method')
          req_id = obj.get('id')

          if method == 'initialize' and req_id is not None:
              print(json.dumps({
                  'id': req_id,
                  'result': {'userAgent': 'fake/1.0'}
              }), flush=True)
          elif method == 'account/rateLimits/read' and req_id is not None:
              if not os.path.exists(marker):
                  open(marker, 'w').close()
                  sys.exit(0)

              print(json.dumps({
                  'id': req_id,
                  'result': {
                      'rateLimits': {
                          'primary': {
                              'usedPercent': 7,
                              'windowDurationMins': 300,
                              'resetsAt': 1789069799
                          },
                          'secondary': {
                              'usedPercent': 82,
                              'windowDurationMins': 10080,
                              'resetsAt': 1789447124
                          }
                      }
                  }
              }), flush=True)
      """

    try script.write(to: executable, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: executable.path
    )

    let client = CodexAppServerClient(
      executableURL: executable,
      requestTimeoutNanoseconds: 2_000_000_000
    )

    do {
      _ = try await client.fetchRateLimits()
      XCTFail("Expected first child process to terminate")
    } catch let error as CodexAppServerClient.ClientError {
      XCTAssertEqual(error, .processStopped)
    }

    let recovered = try await client.fetchRateLimits()
    XCTAssertEqual(recovered.fiveHour?.remainingPercent, 93)
    XCTAssertEqual(recovered.weekly?.remainingPercent, 18)

    await client.stop()
  }

  func testStopClosesTheChildProcess() async throws {
    let tempDir = FileManager.default.temporaryDirectory
      .appendingPathComponent("codex-usage-stop-\(UUID().uuidString)")
    let executable = tempDir.appendingPathComponent("fake-codex.py")
    let exitMarker = tempDir.appendingPathComponent("exited.marker")

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let markerLiteral = exitMarker.path
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "'", with: "\\'")

    let script = """
      #!/usr/bin/env python3
      import json
      import sys
      import time

      marker = '\(markerLiteral)'

      try:
          for line in sys.stdin:
              try:
                  obj = json.loads(line)
              except Exception:
                  continue

              method = obj.get('method')
              req_id = obj.get('id')

              if method == 'initialize' and req_id is not None:
                  print(json.dumps({
                      'id': req_id,
                      'result': {'userAgent': 'fake/1.0'}
                  }), flush=True)
              elif method == 'account/rateLimits/read' and req_id is not None:
                  print(json.dumps({
                      'id': req_id,
                      'result': {
                          'rateLimits': {
                              'primary': {
                                  'usedPercent': 1,
                                  'windowDurationMins': 300,
                                  'resetsAt': 1789069799
                              },
                              'secondary': {
                                  'usedPercent': 2,
                                  'windowDurationMins': 10080,
                                  'resetsAt': 1789447124
                              }
                          }
                      }
                  }), flush=True)
      finally:
          # Deliberately take a moment to complete graceful EOF shutdown.
          # R4's immediate terminate() raced this path on real macOS.
          time.sleep(0.10)
          open(marker, 'w').close()
      """

    try script.write(to: executable, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: executable.path
    )

    let client = CodexAppServerClient(executableURL: executable)
    _ = try await client.fetchRateLimits()
    await client.stop()

    let deadline = Date().addingTimeInterval(2)
    while !FileManager.default.fileExists(atPath: exitMarker.path), Date() < deadline {
      try await Task.sleep(nanoseconds: 20_000_000)
    }

    XCTAssertTrue(FileManager.default.fileExists(atPath: exitMarker.path))
  }

}
