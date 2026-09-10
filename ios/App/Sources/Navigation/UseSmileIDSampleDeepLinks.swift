/// The deep-link URI per route: paths are shared across the four apps, the scheme is per app, so these live in the shell.
enum UseSmileIDSampleDeepLinks {
  static let scheme = "usesmileid-sample-ios"

  static let products = "\(scheme)://products"
  static let verifications = "\(scheme)://verifications"
  static let verificationDetails = "\(scheme)://verifications/{jobId}"
  static let settings = "\(scheme)://settings"

  static let consentDetailsForm = "\(scheme)://flow/{productId}/details"
  static let idDetailsForm = "\(scheme)://flow/{productId}/id-details"
  static let countryPicker = "\(scheme)://flow/{productId}/id-details/country"
  static let idTypePicker = "\(scheme)://flow/{productId}/id-details/id-type"
  static let sdkFlow = "\(scheme)://flow/{productId}/run?route={route}"

  static let profiles = "\(scheme)://profiles"
  static let profileSwitch = "\(scheme)://profiles/switch"
  static let newProfile = "\(scheme)://profiles/new"
  static let profileConfig = "\(scheme)://profiles/{profileId}"

  static let licenses = "\(scheme)://settings/licenses"

  static let scanToken = "\(scheme)://token/scan"
  static let scenarioDrawer = "\(scheme)://debug/scenarios"
}
