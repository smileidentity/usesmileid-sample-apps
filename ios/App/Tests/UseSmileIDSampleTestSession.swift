import Foundation
import SampleUI

/// A sandbox session binding nothing, which every run now needs before it reaches the SDK.
let useSmileIDSampleTestSession = UseSmileIDSampleTokenSession(
  id: "handle",
  token: "token",
  issuedAt: Date(timeIntervalSince1970: 1000000),
  expiresAt: Date(timeIntervalSince1970: 1003600),
  bindings: UseSmileIDSampleTokenBindings(),
  partnerId: "0000",
  environment: .sandbox
)
