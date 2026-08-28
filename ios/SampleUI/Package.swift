// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SampleUI",
  // The SDK's own floor: raising it would stop the SDK repo's Sample compiling this against HEAD.
  platforms: [.iOS(.v15)],
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
