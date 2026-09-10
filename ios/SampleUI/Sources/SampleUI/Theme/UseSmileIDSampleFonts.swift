import CoreText
import SwiftUI

/// The bundled DM Sans faces and the weight-to-face rule the ramp resolves through: shipped, not fetched, so no golden needs the network.
public enum UseSmileIDSampleFonts {
  /// The ramp's weights (400–800) by PostScript name: the files carry three family names, so asking "DM Sans" for semibold gives regular.
  static let faces: [Int: String] = [
    400: "DMSans-Regular",
    500: "DMSans-Medium",
    600: "DMSans-SemiBold",
    700: "DMSans-Bold",
    800: "DMSans-ExtraBold"
  ]

  /// Registered once, lazily and atomically: a package's resources are invisible to the app's `UIAppFonts`.
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

  /// The face for a numeric weight, nearest match, registering on the way: an unregistered name renders in the system font.
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

  /// The font for one ramp style; `relativeTo: .body` makes a custom face honour Dynamic Type and scales the ramp by one factor.
  public static func font(_ style: SmileTextStyle) -> Font {
    .custom(face(weight: style.weight), size: style.size, relativeTo: .body)
  }
}
