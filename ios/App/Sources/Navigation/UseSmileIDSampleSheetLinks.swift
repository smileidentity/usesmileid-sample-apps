import Foundation

/// A sheet's link resolves to its owner's link plus a sheet request, never to a destination.
struct UseSmileIDSampleSheetLink: Equatable {
  let sheet: Sheet
  let ownerUri: String
}

/// String in, string out, so `spec/routes.json` can assert the whole table without a device.
enum UseSmileIDSampleSheetLinks {
  /// Nil for every other link, which the route table claims itself.
  static func resolve(_ link: String) -> UseSmileIDSampleSheetLink? {
    // `probes` reaches the app off the launch arguments, not off the route.
    let uri = String(link.prefix(while: { $0 != "?" && $0 != "#" }))
    if let fixed = fixed[uri] {
      return fixed
    }
    guard let lastSlash = uri.lastIndex(of: "/") else { return nil }
    guard let sheet = pickers[String(uri[uri.index(after: lastSlash)...])] else { return nil }
    let owner = String(uri[..<lastSlash])
    guard owner.range(of: idDetailsPattern, options: .regularExpression) != nil else { return nil }
    return UseSmileIDSampleSheetLink(sheet: sheet, ownerUri: owner)
  }

  /// Owners that share no path with their sheet, so the pairing has to be stated.
  private static let fixed: [String: UseSmileIDSampleSheetLink] = [
    UseSmileIDSampleDeepLinks.profileSwitch:
      UseSmileIDSampleSheetLink(sheet: .profileSwitch, ownerUri: UseSmileIDSampleDeepLinks.products),
    UseSmileIDSampleDeepLinks.newProfile:
      UseSmileIDSampleSheetLink(sheet: .newProfile, ownerUri: UseSmileIDSampleDeepLinks.profiles),
    UseSmileIDSampleDeepLinks.scenarioDrawer:
      UseSmileIDSampleSheetLink(sheet: .scenarioDrawer, ownerUri: UseSmileIDSampleDeepLinks.settings)
  ]

  /// The pickers hang off the form's own path, so their owner is the link minus its last segment.
  private static let pickers: [String: Sheet] = [
    lastSegment(UseSmileIDSampleDeepLinks.countryPicker): .countryPicker,
    lastSegment(UseSmileIDSampleDeepLinks.idTypePicker): .idTypePicker
  ]

  /// Built from the constant so a renamed path cannot leave this behind.
  private static let idDetailsPattern: String = {
    let parts = UseSmileIDSampleDeepLinks.idDetailsForm.components(separatedBy: "{productId}")
    return "^" + NSRegularExpression.escapedPattern(for: parts[0])
      + "[^/]+" + NSRegularExpression.escapedPattern(for: parts[1]) + "$"
  }()

  private static func lastSegment(_ uri: String) -> String {
    String(uri[uri.index(after: uri.lastIndex(of: "/")!)...])
  }
}
