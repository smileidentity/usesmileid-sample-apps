// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SampleUI",
  // Above the SDK's own floor of 15, so the store can be SwiftData rather than a JSON document —
  // see docs/plan/offline-storage.md D1. The SDK repo's Sample has to match when `sample-ui` is
  // finally wired into it; nothing consumes this library that way yet.
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "SampleUI", targets: ["SampleUI"])
  ],
  dependencies: [
    // Registry-only, permanently; the SDK repo substitutes its source layer by identity (§9.1).
    .package(url: "https://github.com/smileidentity/ios-spm.git", exact: "12.0.2"),
    // Test-only, so it never reaches the SDK repo's Sample: SwiftPM resolves no dependency that
    // only a non-root package's tests use. Same tool and pin as the SDK repo's snapshot gate.
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.4")
  ],
  targets: [
    .target(
      name: "SampleUI",
      dependencies: [.product(name: "UseSmileID", package: "ios-spm")],
      // Copied, not processed, so the faces keep the subdirectory the registrar enumerates.
      resources: [.copy("Resources/Fonts")]
    ),
    .testTarget(name: "SampleUITests", dependencies: ["SampleUI"]),
    // Its own target so `ios/verify.sh` has a golden step it can name, and so the snapshot
    // dependency reaches nothing else. The Compose twin is the separate verifyRoborazzi task.
    .testTarget(
      name: "SampleUIGoldenTests",
      dependencies: [
        "SampleUI",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ]
    )
  ]
)
