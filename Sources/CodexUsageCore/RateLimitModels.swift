import Foundation

public struct QuotaWindow: Equatable, Sendable {
  public let usedPercent: Double
  public let windowDurationMins: Int
  public let resetsAt: TimeInterval

  public init(usedPercent: Double, windowDurationMins: Int, resetsAt: TimeInterval) {
    self.usedPercent = usedPercent
    self.windowDurationMins = windowDurationMins
    self.resetsAt = resetsAt
  }

  public var remainingPercent: Double {
    min(100, max(0, 100 - usedPercent))
  }
}

public struct CodexQuotaSnapshot: Equatable, Sendable {
  public let fiveHour: QuotaWindow?
  public let weekly: QuotaWindow?

  public init(fiveHour: QuotaWindow?, weekly: QuotaWindow?) {
    self.fiveHour = fiveHour
    self.weekly = weekly
  }
}

public enum RateLimitParseError: Error, Equatable {
  case rpcError(String)
  case missingRateLimits
}

private struct RPCErrorPayload: Decodable {
  let message: String?
}

private struct RateLimitsEnvelope: Decodable {
  struct ResultPayload: Decodable {
    let rateLimits: RateLimitWire?
    let rateLimitsByLimitId: [String: RateLimitWire]?
  }

  let result: ResultPayload?
  let error: RPCErrorPayload?
}

private struct RateLimitWire: Decodable {
  let primary: RateLimitWindowWire?
  let secondary: RateLimitWindowWire?

  var windows: [QuotaWindow] {
    [primary, secondary].compactMap { $0?.model }
  }
}

private struct RateLimitWindowWire: Decodable {
  let usedPercent: Double
  let windowDurationMins: Int
  let resetsAt: TimeInterval

  var model: QuotaWindow {
    QuotaWindow(
      usedPercent: usedPercent,
      windowDurationMins: windowDurationMins,
      resetsAt: resetsAt
    )
  }
}

public enum RateLimitParser {
  public static func parseRateLimits(from data: Data) throws -> CodexQuotaSnapshot {
    let envelope = try JSONDecoder().decode(RateLimitsEnvelope.self, from: data)

    if let error = envelope.error {
      throw RateLimitParseError.rpcError(error.message ?? "Unknown RPC error")
    }

    guard let result = envelope.result else {
      throw RateLimitParseError.missingRateLimits
    }

    // The current protocol normally returns both forms. Merge them so a partial
    // direct snapshot can still be completed by rateLimitsByLimitId.codex.
    let windows =
      (result.rateLimits?.windows ?? [])
      + (result.rateLimitsByLimitId?["codex"]?.windows ?? [])

    let fiveHour = windows.first(where: { $0.windowDurationMins == 300 })
    let weekly = windows.first(where: { $0.windowDurationMins == 10_080 })

    guard fiveHour != nil || weekly != nil else {
      throw RateLimitParseError.missingRateLimits
    }

    return CodexQuotaSnapshot(
      fiveHour: fiveHour,
      weekly: weekly
    )
  }
}
