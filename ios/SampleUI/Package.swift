// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "SampleUI",
  // iOS 15 is the SDK's own floor (ios-spm's manifest). Raising it here would stop the iOS SDK
  // repo's Sample, which is iOS 15.0, from compiling this library against SDK HEAD.
  platforms: [.iOS(.v15)],
  products: [
    .library(name: "SampleUI", targets: ["SampleUI"])
  ],
  dependencies: [
    // Registry-only, permanently: the published package, pinned to the stable tag. The SDK repo
    // substitutes its source layer by identity — see docs/plan/sample-apps-plan.md §9.1.
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
