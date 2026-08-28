/// A sheet is a LAYER over the screen that owns it, never a destination that replaces it — R12 in
/// `docs/plan/navigation-plan.md`. SwiftUI gets this right by construction: `.sheet` presents over
/// the presenter, so the screen underneath stays alive and drawn.
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
