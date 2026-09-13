import Foundation
import XCTest

@testable import CodexUsageCore

final class RateLimitParserTests: XCTestCase {
  func testParsesFiveHourAndWeeklyWindowsAndComputesRemaining() throws {
    let json = #"""
      {
        "id": 2,
        "result": {
          "rateLimits": {
            "limitId": "codex",
            "limitName": null,
            "primary": {
              "usedPercent": 0,
              "windowDurationMins": 300,
              "resetsAt": 1789069799
            },
            "secondary": {
              "usedPercent": 99,
              "windowDurationMins": 10080,
              "resetsAt": 1789447124
            }
          }
        }
      }
      """#.data(using: .utf8)!

    let snapshot = try RateLimitParser.parseRateLimits(from: json)

    XCTAssertEqual(snapshot.fiveHour?.windowDurationMins, 300)
    XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 100)
    XCTAssertEqual(snapshot.weekly?.windowDurationMins, 10_080)
    XCTAssertEqual(snapshot.weekly?.remainingPercent, 1)
  }

  func testFallsBackToCodexEntryInRateLimitsByLimitId() throws {
    let json = #"""
      {
        "id": 2,
        "result": {
          "rateLimitsByLimitId": {
            "codex": {
              "primary": {
                "usedPercent": 25,
                "windowDurationMins": 300,
                "resetsAt": 1789069799
              },
              "secondary": {
                "usedPercent": 75,
                "windowDurationMins": 10080,
                "resetsAt": 1789447124
              }
            }
          }
        }
      }
      """#.data(using: .utf8)!

    let snapshot = try RateLimitParser.parseRateLimits(from: json)

    XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 75)
    XCTAssertEqual(snapshot.weekly?.remainingPercent, 25)
  }

  func testMergesPartialDirectAndCodexByLimitIDPayloads() throws {
    let json = #"""
      {
        "id": 2,
        "result": {
          "rateLimits": {
            "primary": {
              "usedPercent": 20,
              "windowDurationMins": 300,
              "resetsAt": 1789069799
            },
            "secondary": null
          },
          "rateLimitsByLimitId": {
            "codex": {
              "primary": null,
              "secondary": {
                "usedPercent": 40,
                "windowDurationMins": 10080,
                "resetsAt": 1789447124
              }
            }
          }
        }
      }
      """#.data(using: .utf8)!

    let snapshot = try RateLimitParser.parseRateLimits(from: json)

    XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 80)
    XCTAssertEqual(snapshot.weekly?.remainingPercent, 60)
  }

  func testIdentifiesWindowsByDurationEvenIfPrimarySecondaryOrderChanges() throws {
    let json = #"""
      {
        "id": 2,
        "result": {
          "rateLimits": {
            "primary": {
              "usedPercent": 65,
              "windowDurationMins": 10080,
              "resetsAt": 1789447124
            },
            "secondary": {
              "usedPercent": 10,
              "windowDurationMins": 300,
              "resetsAt": 1789069799
            }
          }
        }
      }
      """#.data(using: .utf8)!

    let snapshot = try RateLimitParser.parseRateLimits(from: json)

    XCTAssertEqual(snapshot.fiveHour?.remainingPercent, 90)
    XCTAssertEqual(snapshot.weekly?.remainingPercent, 35)
  }

  func testRejectsPayloadWithoutExpectedCodexWindows() throws {
    let json = #"""
      {
        "id": 2,
        "result": {
          "rateLimits": {
            "primary": {
              "usedPercent": 10,
              "windowDurationMins": 60,
              "resetsAt": 1789069799
            },
            "secondary": null
          }
        }
      }
      """#.data(using: .utf8)!

    XCTAssertThrowsError(try RateLimitParser.parseRateLimits(from: json)) { error in
      XCTAssertEqual(error as? RateLimitParseError, .missingRateLimits)
    }
  }

  func testPropagatesRPCError() throws {
    let json = #"""
      {
        "id": 2,
        "error": {
          "message": "rate limit unavailable"
        }
      }
      """#.data(using: .utf8)!

    XCTAssertThrowsError(try RateLimitParser.parseRateLimits(from: json)) { error in
      XCTAssertEqual(
        error as? RateLimitParseError,
        .rpcError("rate limit unavailable")
      )
    }
  }

  func testClampsRemainingPercent() {
    XCTAssertEqual(
      QuotaWindow(usedPercent: -5, windowDurationMins: 300, resetsAt: 0).remainingPercent,
      100
    )
    XCTAssertEqual(
      QuotaWindow(usedPercent: 120, windowDurationMins: 300, resetsAt: 0).remainingPercent,
      0
    )
  }
}
