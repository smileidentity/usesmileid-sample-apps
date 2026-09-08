import SampleUI
import SwiftUI
import UIKit

/// The consent screen takes a `UIImage` and this app's marks are SwiftUI shapes, so one is drawn
/// rather than a second copy of the asset shipped.
enum UseSmileIDSampleFlowIcon {
  /// What the Compose twin passes as `sample_ic_product_mark`.
  static let partnerMark: UIImage = image(SmileIcons.productMark, size: markSize)

  private static func image(_ icon: SmileIcon, size: CGFloat) -> UIImage {
    let scale = min(size / icon.width, size / icon.height)
    let transform = CGAffineTransform(translationX: -icon.minX, y: -icon.minY)
      .concatenating(CGAffineTransform(scaleX: scale, y: scale))
    return UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { context in
      // Template-tinted by the SDK's theme, so one opaque colour is enough.
      UIColor.label.setFill()
      UIColor.label.setStroke()
      for part in icon.parts {
        var path = Path()
        part.build(&path)
        context.cgContext.setAlpha(part.opacity)
        context.cgContext.addPath(path.applying(transform).cgPath)
        switch part.stroke {
        case .fill:
          context.cgContext.fillPath()
        case .stroke(let width, let round):
          context.cgContext.setLineWidth(width * scale)
          context.cgContext.setLineCap(round ? .round : .butt)
          context.cgContext.setLineJoin(round ? .round : .miter)
          context.cgContext.strokePath()
        }
      }
    }
    .withRenderingMode(.alwaysTemplate)
  }

  private static let markSize: CGFloat = 48
}
