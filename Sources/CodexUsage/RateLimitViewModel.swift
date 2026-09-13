import CodexUsageCore
import CodexUsageTransport
import Foundation
import SwiftUI

@MainActor
final class RateLimitViewModel: ObservableObject {
  @Published private(set) var snapshot: CodexQuotaSnapshot?
  @Published private(set) var errorMessage: String?

  private let client: CodexAppServerClient?
  private var refreshTask: Task<Void, Never>?
  private var consecutiveFailures = 0
  private var lastReportedFailureFingerprint: String?

  init() {
    if let executable = CodexExecutableLocator.locate() {
      client = CodexAppServerClient(executableURL: executable)
    } else {
      client = nil
    }
  }

  func start() {
    guard refreshTask == nil else { return }

    if client == nil {
      presentErrorOnce(
        fingerprint: "missing-codex-executable",
        message: "未找到可用的 Codex 可执行文件。请确认 ChatGPT.app 已安装在 /Applications，或系统中存在可用的 Codex.app。"
      )
    }

    refreshTask = Task { [weak self] in
      guard let self else { return }

      while !Task.isCancelled {
        let cycleStartedAt = DispatchTime.now().uptimeNanoseconds

        if let client {
          do {
            let latest = try await client.fetchRateLimits()

            // If one window is temporarily omitted, retain the last successful
            // value for that window instead of flashing a placeholder.
            snapshot = CodexQuotaSnapshot(
              fiveHour: latest.fiveHour ?? snapshot?.fiveHour,
              weekly: latest.weekly ?? snapshot?.weekly
            )

            consecutiveFailures = 0
            lastReportedFailureFingerprint = nil
          } catch {
            consecutiveFailures += 1

            // Surface an initial failure immediately. Once valid data has been shown,
            // tolerate two transient failures before alerting while keeping the
            // last-known-good values on screen.
            if snapshot == nil || consecutiveFailures >= 3 {
              presentErrorOnce(
                fingerprint: String(reflecting: type(of: error)) + ":" + String(describing: error),
                message: "无法读取 Codex 使用额度。请确认 ChatGPT/Codex 已登录且网络可用。Codex Usage 会继续自动重试，恢复后会自行更新。"
              )
            }
          }
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

  func dismissError() {
    errorMessage = nil
  }

  private func presentErrorOnce(fingerprint: String, message: String) {
    guard fingerprint != lastReportedFailureFingerprint else { return }
    lastReportedFailureFingerprint = fingerprint

    if errorMessage == nil {
      errorMessage = message
    }
  }
}
