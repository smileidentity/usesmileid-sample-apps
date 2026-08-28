import CoreText
import SwiftUI

/// The bundled DM Sans faces, and the weight-to-face rule the token ramp resolves through.
///
/// DM Sans is shipped rather than fetched: `spec/design-tokens.json` says to ship it, and a
/// downloaded face would make text — and every golden — depend on the network.
public enum UseSmileIDSampleFonts {
  /// The five faces the ramp's weights (400–800) resolve to, by PostScript name.
  ///
  /// A PostScript name and not `Font.custom("DM Sans").weight(_:)`: the five files carry three
  /// different family names — "DM Sans", "DM Sans Medium", "DM Sans SemiBold" — so asking the
  /// "DM Sans" family for a semibold silently returns the regular face.
  static let faces: [Int: String] = [
    400: "DMSans-Regular",
    500: "DMSans-Medium",
    600: "DMSans-SemiBold",
    700: "DMSans-Bold",
    800: "DMSans-ExtraBold"
  ]

  /// Registered once, lazily and atomically, the first time a style resolves.
  ///
  /// A package's resources are invisible to the app's `UIAppFonts`, so the faces are registered at
  /// runtime instead. `true` once every face is usable.
  @discardableResult
  public static func register() -> Bool {
    registered
  }

  private static let registered: Bool = {
    guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") else {
      return false
    }
    for url in urls {
      var error: Unmanaged<CFError>?
      if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
        // Retained, not unretained: an out-parameter follows the create rule, so the caller owns
        // the error and taking it unretained leaks one object per failed face.
        let code = error.map { CFErrorGetCode($0.takeRetainedValue()) }
        // Already-registered is a success: the SDK ships the same faces and may have got there first.
        if code != CTFontManagerError.alreadyRegistered.rawValue {
          return false
        }
      }
    }
    return faces.values.allSatisfy { UIFont(name: $0, size: 12) != nil }
  }()

  /// The face for a token's numeric weight, falling back to the nearest one that exists.
  ///
  /// Registers on the way through, because every path to a face runs through here: a caller that
  /// got a name without the faces being registered would silently render in the system font.
  static func face(weight: Int) -> String {
    register()
    if let exact = faces[weight] {
      return exact
    }
    // An exact tie takes the lighter face, and says so: comparing distance alone leaves 650 to
    // pick whichever of 600 and 700 the unordered keys happened to yield first.
    let nearest = faces.keys.min { lhs, rhs in
      let left = abs(lhs - weight), right = abs(rhs - weight)
      return left == right ? lhs < rhs : left < right
    }
    return nearest.flatMap { faces[$0] } ?? "DMSans-Regular"
  }

  /// The font for one ramp style. `relativeTo` is what makes a custom face honour Dynamic Type —
  /// a plain `Font.custom(_:size:)` is a fixed size and would ignore it entirely.
  ///
  /// Every style relates to `.body` rather than its nearest system style, so the whole ramp scales
  /// by one factor and the design's hierarchy survives at accessibility sizes instead of flattening.
  public static func font(_ style: SmileTextStyle) -> Font {
    .custom(face(weight: style.weight), size: style.size, relativeTo: .body)
  }
}
