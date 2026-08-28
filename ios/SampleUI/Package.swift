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
    .package(url: "https://github.com/smileidentity/ios-spm.git", exact: "12.0.2")
  ],
  targets: [
    .target(
      name: "SampleUI",
      dependencies: [.product(name: "UseSmileID", package: "ios-spm")]
    ),
    .testTarget(name: "SampleUITests", dependencies: ["SampleUI"])
  ]
)
