import Foundation

/// Deep-link URIs: the paths are shared by the four apps and the scheme is per app, so they live in the shell.
enum UseSmileIDSampleDeepLinks {
  /// The build's scheme, from the plist: a source build injects its own.
  static let scheme: String = {
    let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]]
    guard let scheme = (types?.first?["CFBundleURLSchemes"] as? [String])?.first else {
      preconditionFailure("Info.plist declares no URL scheme")
    }
    return scheme
  }()

  static let products = "\(scheme)://products"
  static let verifications = "\(scheme)://verifications"
  static let verificationDetails = "\(scheme)://verifications/{jobId}"
  static let settings = "\(scheme)://settings"

  static let consentDetailsForm = "\(scheme)://flow/{productId}/details"
  static let authUserId = "\(scheme)://flow/{productId}/user-id"
  static let idDetailsForm = "\(scheme)://flow/{productId}/id-details"
  static let countryPicker = "\(scheme)://flow/{productId}/id-details/country"
  static let idTypePicker = "\(scheme)://flow/{productId}/id-details/id-type"
  static let documentPicker = "\(scheme)://flow/{productId}/id-details/document"
  static let captureAs = "\(scheme)://flow/{productId}/id-details/capture-as"
  static let genericDocument = "\(scheme)://flow/{productId}/id-details/generic-document"
  static let sdkFlow = "\(scheme)://flow/{productId}/run?route={route}"

  static let profiles = "\(scheme)://profiles"
  static let profileSwitch = "\(scheme)://profiles/switch"
  static let newProfile = "\(scheme)://profiles/new"
  static let profileConfig = "\(scheme)://profiles/{profileId}"

  static let licenses = "\(scheme)://settings/licenses"
  static let captureMode = "\(scheme)://settings/capture-mode"
  static let appearance = "\(scheme)://settings/appearance"
  static let language = "\(scheme)://settings/language"

  static let scanToken = "\(scheme)://token/scan"
  static let scenarioDrawer = "\(scheme)://debug/scenarios"
}
