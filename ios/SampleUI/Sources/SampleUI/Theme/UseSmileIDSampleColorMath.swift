import SwiftUI

/// Colour maths the design's fills need, kept with the theme helpers rather than in its first caller.
extension Color {
  /// The standard white-or-dark crossover: above it a fill carries dark ink, below it light.
  var inkOn: Color {
    luminance > 0.179 ? smileOffBlackLight : SmileColorLight.colorTextInverse
  }

  /// WCAG relative luminance, the measure the other three apps cross over on.
  var luminance: CGFloat {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
    UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
    let linear = { (c: CGFloat) in c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
    return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
  }

  func mixed(with other: Color, by fraction: CGFloat) -> Color {
    var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
    var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0
    UIColor(self).getRed(&lr, green: &lg, blue: &lb, alpha: &la)
    UIColor(other).getRed(&rr, green: &rg, blue: &rb, alpha: &ra)
    let t = min(max(fraction, 0), 1)
    return Color(
      .sRGB,
      red: lr + (rr - lr) * t,
      green: lg + (rg - lg) * t,
      blue: lb + (rb - lb) * t,
      opacity: la + (ra - la) * t
    )
  }
}
