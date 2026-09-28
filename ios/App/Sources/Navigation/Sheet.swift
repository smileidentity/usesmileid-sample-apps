/// A sheet layers over the screen that owns it, never replaces it — SwiftUI does this by construction.
enum Sheet: String, Identifiable, Hashable {
  case profileSwitch
  case newProfile
  case scenarioDrawer
  case countryPicker
  case idTypePicker
  case documentPicker
  case captureAs
  case customDocument
  case captureMode

  var id: String {
    rawValue
  }
}
