// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SampleUI",
  // Above the SDK's own floor of 15 so the store can be SwiftData; see docs/architecture.md §5.
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "SampleUI", targets: ["SampleUI"])
  ],
  dependencies: [
    // Registry-only, permanently; the SDK repo substitutes its source layer by identity (§9.1).
    .package(url: "https://github.com/smileidentity/ios-spm.git", exact: "12.1.1"),
    // Test-only, so it never reaches the SDK repo's Sample; same tool and pin as that repo's snapshot gate.
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.6")
  ],
  targets: [
    .target(
      name: "SampleUI",
      dependencies: [.product(name: "UseSmileID", package: "ios-spm")],
      // Copied, not processed: the faces keep their subdirectory and the notices land at the bundle root.
      resources: [.copy("Resources/Fonts"), .copy("Resources/licenses.json")]
    ),
    .testTarget(name: "SampleUITests", dependencies: ["SampleUI"]),
    // Its own target so `ios/verify.sh` can name a golden step and the snapshot dependency reaches nothing else.
    .testTarget(
      name: "SampleUIGoldenTests",
      dependencies: [
        "SampleUI",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ]
    )
  ]
)
