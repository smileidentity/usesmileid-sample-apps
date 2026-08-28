/// A sheet layers over the screen that owns it, never replaces it — SwiftUI does this by construction.
enum Sheet: String, Identifiable, Hashable {
  case profileSwitch
  case newProfile
  case scenarioDrawer
  case countryPicker
  case idTypePicker

  var id: String {
    rawValue
  }
}
