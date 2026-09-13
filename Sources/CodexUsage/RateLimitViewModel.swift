import CodexUsageCore
import CodexUsageTransport
import Foundation
import SwiftUI

@MainActor
final class RateLimitViewModel: ObservableObject {
  @Published private(set) var snapshot: CodexQuotaSnapshot?

  private let client: CodexAppServerClient?
  private var refreshTask: Task<Void, Never>?

  init() {
    if let executable = CodexExecutableLocator.locate() {
      client = CodexAppServerClient(executableURL: executable)
    } else {
      client = nil
    }
  }

  func start() {
    guard refreshTask == nil else { return }

    refreshTask = Task { [weak self] in
      guard let self else { return }

      while !Task.isCancelled {
        let cycleStartedAt = DispatchTime.now().uptimeNanoseconds

        if let client,
          let latest = try? await client.fetchRateLimits()
        {
          // If one window is temporarily omitted, retain the last successful
          // value for that window instead of flashing a placeholder.
          snapshot = CodexQuotaSnapshot(
            fiveHour: latest.fiveHour ?? snapshot?.fiveHour,
            weekly: latest.weekly ?? snapshot?.weekly
          )
        }

        let elapsed = DispatchTime.now().uptimeNanoseconds - cycleStartedAt
        let oneSecond: UInt64 = 1_000_000_000
        let delay = elapsed < oneSecond ? oneSecond - elapsed : 0

        if delay > 0 {
          do {
            try await Task.sleep(nanoseconds: delay)
          } catch {
            break
          }
        }
      }
    }
  }

  func stop() {
    refreshTask?.cancel()
    refreshTask = nil

    if let client {
      Task { await client.stop() }
    }
  }
}
