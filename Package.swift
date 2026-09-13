// swift-tools-version: 6.0
import PackageDescription

var products: [Product] = []
var targets: [Target] = [
  .target(
    name: "CodexUsageCore",
    path: "Sources/CodexUsageCore"
  ),
  .target(
    name: "CodexUsageTransport",
    dependencies: ["CodexUsageCore"],
    path: "Sources/CodexUsageTransport"
  ),
  .testTarget(
    name: "CodexUsageCoreTests",
    dependencies: ["CodexUsageCore"],
    path: "Tests/CodexUsageCoreTests"
  ),
  .testTarget(
    name: "CodexUsageTransportTests",
    dependencies: ["CodexUsageTransport", "CodexUsageCore"],
    path: "Tests/CodexUsageTransportTests"
  ),
]

#if os(macOS)
  products.append(.executable(name: "CodexUsage", targets: ["CodexUsage"]))
  targets.append(
    .executableTarget(
      name: "CodexUsage",
      dependencies: ["CodexUsageCore", "CodexUsageTransport"],
      path: "Sources/CodexUsage"
    )
  )
#endif

let package = Package(
  name: "CodexUsageTitanium",
  platforms: [
    .macOS(.v14)
  ],
  products: products,
  targets: targets
)
