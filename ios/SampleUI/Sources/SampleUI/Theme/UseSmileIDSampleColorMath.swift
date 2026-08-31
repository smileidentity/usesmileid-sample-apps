import SwiftUI

/// Colour maths the design's own fills need. Generic, so it sits beside the other theme helpers
/// rather than inside the one component that happens to use it first.
extension Color {
  /// The standard white-or-dark crossover: above it a fill carries dark ink, below it light.
  var inkOn: Color {
    var white: CGFloat = 0
    UIColor(self).getWhite(&white, alpha: nil)
    return white > 0.179 ? smileOffBlackLight : SmileColorLight.colorTextInverse
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
