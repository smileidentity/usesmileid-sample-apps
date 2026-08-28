// Smile ID icons — GENERATED from design/icons/*.svg. Do not edit by hand.
//
// Regenerate with: scripts/generate_ios_icons.py
//
// SwiftUI cannot render an SVG and this repo will not add a library to do it, so the marks are
// emitted as Shapes in their own viewBox coordinates and scaled to the size the caller asks for.
// The Compose twin consumes the same SVGs as vector drawables.

import SwiftUI

/// How one subpath of a mark is drawn. The design's marks are strokes; the Material Symbols
/// stand-ins are fills, so a mark carries the answer rather than the caller guessing.
public enum SmileIconStroke: Equatable, Sendable {
  case fill
  case stroke(width: CGFloat, round: Bool)
}

/// One mark: its own coordinate space, and the subpaths that draw it.
public struct SmileIcon: Equatable, Sendable {
  public let width: CGFloat
  public let height: CGFloat
  public let minX: CGFloat
  public let minY: CGFloat
  public let parts: [SmileIconPart]
}

public struct SmileIconPart: Equatable, Sendable {
  public let stroke: SmileIconStroke
  /// Inherited down the SVG tree — the scan glyph draws its whole group at 0.45.
  public let opacity: CGFloat
  public let build: @Sendable (inout Path) -> Void

  public static func == (lhs: SmileIconPart, rhs: SmileIconPart) -> Bool {
    lhs.stroke == rhs.stroke && lhs.opacity == rhs.opacity
  }
}

/// Every mark in `design/icons/`, keyed by its file name.
public enum SmileIcons {
  public static let agent = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 7.125, y: 8.86667))
        path.addCurve(to: CGPoint(x: 9.65833, y: 6.33333), control1: CGPoint(x: 8.52412, y: 8.86667), control2: CGPoint(x: 9.65833, y: 7.73245))
        path.addCurve(to: CGPoint(x: 7.125, y: 3.8), control1: CGPoint(x: 9.65833, y: 4.93421), control2: CGPoint(x: 8.52412, y: 3.8))
        path.addCurve(to: CGPoint(x: 4.59167, y: 6.33333), control1: CGPoint(x: 5.72588, y: 3.8), control2: CGPoint(x: 4.59167, y: 4.93421))
        path.addCurve(to: CGPoint(x: 7.125, y: 8.86667), control1: CGPoint(x: 4.59167, y: 7.73245), control2: CGPoint(x: 5.72588, y: 8.86667))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 2.77083, y: 15.0417))
        path.addCurve(to: CGPoint(x: 7.125, y: 11.4), control1: CGPoint(x: 3.24583, y: 12.6667), control2: CGPoint(x: 4.9875, y: 11.4))
        path.addCurve(to: CGPoint(x: 9.2625, y: 11.875), control1: CGPoint(x: 7.91667, y: 11.4), control2: CGPoint(x: 8.62917, y: 11.5583))
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 11.875, y: 12.6667))
        path.addLine(to: CGPoint(x: 13.4583, y: 14.25))
        path.addLine(to: CGPoint(x: 16.625, y: 11.0833))
      }
    ]
  )

  public static let arrowBack = SmileIcon(
    width: 17,
    height: 17,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.5, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 13.4583, y: 8.5))
        path.addLine(to: CGPoint(x: 3.54163, y: 8.5))
        path.move(to: CGPoint(x: 7.79163, y: 12.75))
        path.addLine(to: CGPoint(x: 3.54163, y: 8.5))
        path.addLine(to: CGPoint(x: 7.79163, y: 4.25))
      }
    ]
  )

  public static let arrowForward = SmileIcon(
    width: 9,
    height: 9,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 5.66542e-05, y: 4.99203))
        path.addLine(to: CGPoint(x: 5.66542e-05, y: 3.88803))
        path.addLine(to: CGPoint(x: 6.69606, y: 3.88803))
        path.addLine(to: CGPoint(x: 3.34806, y: 0.76803))
        path.addLine(to: CGPoint(x: 4.10406, y: 2.95639e-05))
        path.addLine(to: CGPoint(x: 8.40006, y: 4.09203))
        path.addLine(to: CGPoint(x: 8.40006, y: 4.75203))
        path.addLine(to: CGPoint(x: 4.10406, y: 8.85603))
        path.addLine(to: CGPoint(x: 3.34806, y: 8.08803))
        path.addLine(to: CGPoint(x: 6.67206, y: 4.99203))
        path.addLine(to: CGPoint(x: 5.66542e-05, y: 4.99203))
        path.closeSubpath()
      }
    ]
  )

  public static let biometricKyc = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 16.625, y: 3.5))
        path.addLine(to: CGPoint(x: 4.375, y: 3.5))
        path.addCurve(to: CGPoint(x: 2.625, y: 5.25), control1: CGPoint(x: 3.4085, y: 3.5), control2: CGPoint(x: 2.625, y: 4.2835))
        path.addLine(to: CGPoint(x: 2.625, y: 15.75))
        path.addCurve(to: CGPoint(x: 4.375, y: 17.5), control1: CGPoint(x: 2.625, y: 16.7165), control2: CGPoint(x: 3.4085, y: 17.5))
        path.addLine(to: CGPoint(x: 16.625, y: 17.5))
        path.addCurve(to: CGPoint(x: 18.375, y: 15.75), control1: CGPoint(x: 17.5915, y: 17.5), control2: CGPoint(x: 18.375, y: 16.7165))
        path.addLine(to: CGPoint(x: 18.375, y: 5.25))
        path.addCurve(to: CGPoint(x: 16.625, y: 3.5), control1: CGPoint(x: 18.375, y: 4.2835), control2: CGPoint(x: 17.5915, y: 3.5))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 7.43745, y: 10.675))
        path.addCurve(to: CGPoint(x: 9.36245, y: 8.74995), control1: CGPoint(x: 8.5006, y: 10.675), control2: CGPoint(x: 9.36245, y: 9.8131))
        path.addCurve(to: CGPoint(x: 7.43745, y: 6.82495), control1: CGPoint(x: 9.36245, y: 7.6868), control2: CGPoint(x: 8.5006, y: 6.82495))
        path.addCurve(to: CGPoint(x: 5.51245, y: 8.74995), control1: CGPoint(x: 6.3743, y: 6.82495), control2: CGPoint(x: 5.51245, y: 7.6868))
        path.addCurve(to: CGPoint(x: 7.43745, y: 10.675), control1: CGPoint(x: 5.51245, y: 9.8131), control2: CGPoint(x: 6.3743, y: 10.675))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 4.375, y: 14))
        path.addCurve(to: CGPoint(x: 7.4375, y: 11.8125), control1: CGPoint(x: 4.9, y: 12.425), control2: CGPoint(x: 6.125, y: 11.8125))
        path.addCurve(to: CGPoint(x: 10.5, y: 14), control1: CGPoint(x: 8.75, y: 11.8125), control2: CGPoint(x: 9.975, y: 12.425))
        path.move(to: CGPoint(x: 12.25, y: 7.875))
        path.addLine(to: CGPoint(x: 16.625, y: 7.875))
        path.move(to: CGPoint(x: 12.25, y: 11.375))
        path.addLine(to: CGPoint(x: 16.625, y: 11.375))
      }
    ]
  )

  public static let check = SmileIcon(
    width: 960,
    height: 960,
    minX: 0,
    minY: -960,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 382, y: -240))
        path.addLine(to: CGPoint(x: 154, y: -468))
        path.addLine(to: CGPoint(x: 211, y: -525))
        path.addLine(to: CGPoint(x: 382, y: -354))
        path.addLine(to: CGPoint(x: 749, y: -721))
        path.addLine(to: CGPoint(x: 806, y: -664))
        path.addLine(to: CGPoint(x: 382, y: -240))
        path.closeSubpath()
      }
    ]
  )

  public static let chevron = SmileIcon(
    width: 14,
    height: 14,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.16667, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 5.25, y: 3.5))
        path.addLine(to: CGPoint(x: 8.75, y: 7))
        path.addLine(to: CGPoint(x: 5.25, y: 10.5))
      }
    ]
  )

  public static let chevronDown = SmileIcon(
    width: 12,
    height: 12,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 2, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 2, y: 4))
        path.addLine(to: CGPoint(x: 6, y: 8))
        path.addLine(to: CGPoint(x: 10, y: 4))
      }
    ]
  )

  public static let consent = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 14.25, y: 2.375))
        path.addLine(to: CGPoint(x: 4.75, y: 2.375))
        path.addCurve(to: CGPoint(x: 3.16667, y: 3.95833), control1: CGPoint(x: 3.87555, y: 2.375), control2: CGPoint(x: 3.16667, y: 3.08388))
        path.addLine(to: CGPoint(x: 3.16667, y: 15.0417))
        path.addCurve(to: CGPoint(x: 4.75, y: 16.625), control1: CGPoint(x: 3.16667, y: 15.9161), control2: CGPoint(x: 3.87555, y: 16.625))
        path.addLine(to: CGPoint(x: 14.25, y: 16.625))
        path.addCurve(to: CGPoint(x: 15.8333, y: 15.0417), control1: CGPoint(x: 15.1245, y: 16.625), control2: CGPoint(x: 15.8333, y: 15.9161))
        path.addLine(to: CGPoint(x: 15.8333, y: 3.95833))
        path.addCurve(to: CGPoint(x: 14.25, y: 2.375), control1: CGPoint(x: 15.8333, y: 3.08388), control2: CGPoint(x: 15.1245, y: 2.375))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 7.125, y: 9.5))
        path.addLine(to: CGPoint(x: 8.70833, y: 11.0833))
        path.addLine(to: CGPoint(x: 11.875, y: 7.91667))
      }
    ]
  )

  public static let copy = SmileIcon(
    width: 960,
    height: 960,
    minX: 0,
    minY: -960,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 360, y: -240))
        path.addQuadCurve(to: CGPoint(x: 303.5, y: -263.5), control: CGPoint(x: 327, y: -240))
        path.addQuadCurve(to: CGPoint(x: 280, y: -320), control: CGPoint(x: 280, y: -287))
        path.addLine(to: CGPoint(x: 280, y: -800))
        path.addQuadCurve(to: CGPoint(x: 303.5, y: -856.5), control: CGPoint(x: 280, y: -833))
        path.addQuadCurve(to: CGPoint(x: 360, y: -880), control: CGPoint(x: 327, y: -880))
        path.addLine(to: CGPoint(x: 720, y: -880))
        path.addQuadCurve(to: CGPoint(x: 776.5, y: -856.5), control: CGPoint(x: 753, y: -880))
        path.addQuadCurve(to: CGPoint(x: 800, y: -800), control: CGPoint(x: 800, y: -833))
        path.addLine(to: CGPoint(x: 800, y: -320))
        path.addQuadCurve(to: CGPoint(x: 776.5, y: -263.5), control: CGPoint(x: 800, y: -287))
        path.addQuadCurve(to: CGPoint(x: 720, y: -240), control: CGPoint(x: 753, y: -240))
        path.addLine(to: CGPoint(x: 360, y: -240))
        path.closeSubpath()
        path.move(to: CGPoint(x: 360, y: -320))
        path.addLine(to: CGPoint(x: 720, y: -320))
        path.addLine(to: CGPoint(x: 720, y: -800))
        path.addLine(to: CGPoint(x: 360, y: -800))
        path.addLine(to: CGPoint(x: 360, y: -320))
        path.closeSubpath()
        path.move(to: CGPoint(x: 200, y: -80))
        path.addQuadCurve(to: CGPoint(x: 143.5, y: -103.5), control: CGPoint(x: 167, y: -80))
        path.addQuadCurve(to: CGPoint(x: 120, y: -160), control: CGPoint(x: 120, y: -127))
        path.addLine(to: CGPoint(x: 120, y: -720))
        path.addLine(to: CGPoint(x: 200, y: -720))
        path.addLine(to: CGPoint(x: 200, y: -160))
        path.addLine(to: CGPoint(x: 640, y: -160))
        path.addLine(to: CGPoint(x: 640, y: -80))
        path.addLine(to: CGPoint(x: 200, y: -80))
        path.closeSubpath()
        path.move(to: CGPoint(x: 360, y: -320))
        path.addLine(to: CGPoint(x: 360, y: -800))
        path.addLine(to: CGPoint(x: 360, y: -320))
        path.closeSubpath()
      }
    ]
  )

  public static let darkMode = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.5, y: 12.6667))
        path.addCurve(to: CGPoint(x: 12.6667, y: 9.5), control1: CGPoint(x: 11.2489, y: 12.6667), control2: CGPoint(x: 12.6667, y: 11.2489))
        path.addCurve(to: CGPoint(x: 9.5, y: 6.33333), control1: CGPoint(x: 12.6667, y: 7.7511), control2: CGPoint(x: 11.2489, y: 6.33333))
        path.addCurve(to: CGPoint(x: 6.33333, y: 9.5), control1: CGPoint(x: 7.7511, y: 6.33333), control2: CGPoint(x: 6.33333, y: 7.7511))
        path.addCurve(to: CGPoint(x: 9.5, y: 12.6667), control1: CGPoint(x: 6.33333, y: 11.2489), control2: CGPoint(x: 7.7511, y: 12.6667))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.5, y: 1.58333))
        path.addLine(to: CGPoint(x: 9.5, y: 3.16667))
        path.move(to: CGPoint(x: 9.5, y: 15.8333))
        path.addLine(to: CGPoint(x: 9.5, y: 17.4167))
        path.move(to: CGPoint(x: 1.58333, y: 9.5))
        path.addLine(to: CGPoint(x: 3.16667, y: 9.5))
        path.move(to: CGPoint(x: 15.8333, y: 9.5))
        path.addLine(to: CGPoint(x: 17.4167, y: 9.5))
        path.move(to: CGPoint(x: 3.95833, y: 3.95833))
        path.addLine(to: CGPoint(x: 5.14583, y: 5.14583))
        path.move(to: CGPoint(x: 13.8542, y: 13.8542))
        path.addLine(to: CGPoint(x: 15.0417, y: 15.0417))
        path.move(to: CGPoint(x: 15.0417, y: 3.95833))
        path.addLine(to: CGPoint(x: 13.8542, y: 5.14583))
        path.move(to: CGPoint(x: 5.14583, y: 13.8542))
        path.addLine(to: CGPoint(x: 3.95833, y: 15.0417))
      }
    ]
  )

  public static let docs = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 3.16667, y: 3.16667))
        path.addLine(to: CGPoint(x: 11.875, y: 3.16667))
        path.addLine(to: CGPoint(x: 15.8333, y: 7.125))
        path.addLine(to: CGPoint(x: 15.8333, y: 15.8333))
        path.addLine(to: CGPoint(x: 3.16667, y: 15.8333))
        path.addLine(to: CGPoint(x: 3.16667, y: 3.16667))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 6.33333, y: 9.5))
        path.addLine(to: CGPoint(x: 12.6667, y: 9.5))
        path.move(to: CGPoint(x: 6.33333, y: 12.6667))
        path.addLine(to: CGPoint(x: 10.2917, y: 12.6667))
      }
    ]
  )

  public static let documentVerification = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 15.75, y: 2.625))
        path.addLine(to: CGPoint(x: 5.25, y: 2.625))
        path.addCurve(to: CGPoint(x: 3.5, y: 4.375), control1: CGPoint(x: 4.2835, y: 2.625), control2: CGPoint(x: 3.5, y: 3.4085))
        path.addLine(to: CGPoint(x: 3.5, y: 16.625))
        path.addCurve(to: CGPoint(x: 5.25, y: 18.375), control1: CGPoint(x: 3.5, y: 17.5915), control2: CGPoint(x: 4.2835, y: 18.375))
        path.addLine(to: CGPoint(x: 15.75, y: 18.375))
        path.addCurve(to: CGPoint(x: 17.5, y: 16.625), control1: CGPoint(x: 16.7165, y: 18.375), control2: CGPoint(x: 17.5, y: 17.5915))
        path.addLine(to: CGPoint(x: 17.5, y: 4.375))
        path.addCurve(to: CGPoint(x: 15.75, y: 2.625), control1: CGPoint(x: 17.5, y: 3.4085), control2: CGPoint(x: 16.7165, y: 2.625))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 7, y: 7))
        path.addLine(to: CGPoint(x: 14, y: 7))
        path.move(to: CGPoint(x: 7, y: 10.5))
        path.addLine(to: CGPoint(x: 14, y: 10.5))
        path.move(to: CGPoint(x: 7, y: 14))
        path.addLine(to: CGPoint(x: 11.375, y: 14))
      }
    ]
  )

  public static let enhancedKyc = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 16.625, y: 3.5))
        path.addLine(to: CGPoint(x: 4.375, y: 3.5))
        path.addCurve(to: CGPoint(x: 2.625, y: 5.25), control1: CGPoint(x: 3.4085, y: 3.5), control2: CGPoint(x: 2.625, y: 4.2835))
        path.addLine(to: CGPoint(x: 2.625, y: 15.75))
        path.addCurve(to: CGPoint(x: 4.375, y: 17.5), control1: CGPoint(x: 2.625, y: 16.7165), control2: CGPoint(x: 3.4085, y: 17.5))
        path.addLine(to: CGPoint(x: 16.625, y: 17.5))
        path.addCurve(to: CGPoint(x: 18.375, y: 15.75), control1: CGPoint(x: 17.5915, y: 17.5), control2: CGPoint(x: 18.375, y: 16.7165))
        path.addLine(to: CGPoint(x: 18.375, y: 5.25))
        path.addCurve(to: CGPoint(x: 16.625, y: 3.5), control1: CGPoint(x: 18.375, y: 4.2835), control2: CGPoint(x: 17.5915, y: 3.5))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 5.5125, y: 7))
        path.addLine(to: CGPoint(x: 15.4875, y: 7))
        path.move(to: CGPoint(x: 5.5125, y: 10.5))
        path.addLine(to: CGPoint(x: 15.4875, y: 10.5))
        path.move(to: CGPoint(x: 5.5125, y: 14))
        path.addLine(to: CGPoint(x: 11.8125, y: 14))
      }
    ]
  )

  public static let fieldEmail = SmileIcon(
    width: 17,
    height: 17,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.41667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 13.4583, y: 3.54167))
        path.addLine(to: CGPoint(x: 3.54167, y: 3.54167))
        path.addCurve(to: CGPoint(x: 2.125, y: 4.95833), control1: CGPoint(x: 2.75926, y: 3.54167), control2: CGPoint(x: 2.125, y: 4.17593))
        path.addLine(to: CGPoint(x: 2.125, y: 12.0417))
        path.addCurve(to: CGPoint(x: 3.54167, y: 13.4583), control1: CGPoint(x: 2.125, y: 12.8241), control2: CGPoint(x: 2.75926, y: 13.4583))
        path.addLine(to: CGPoint(x: 13.4583, y: 13.4583))
        path.addCurve(to: CGPoint(x: 14.875, y: 12.0417), control1: CGPoint(x: 14.2407, y: 13.4583), control2: CGPoint(x: 14.875, y: 12.8241))
        path.addLine(to: CGPoint(x: 14.875, y: 4.95833))
        path.addCurve(to: CGPoint(x: 13.4583, y: 3.54167), control1: CGPoint(x: 14.875, y: 4.17593), control2: CGPoint(x: 14.2407, y: 3.54167))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.41667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 2.125, y: 4.95833))
        path.addLine(to: CGPoint(x: 8.5, y: 9.20833))
        path.addLine(to: CGPoint(x: 14.875, y: 4.95833))
      }
    ]
  )

  public static let fieldPerson = SmileIcon(
    width: 17,
    height: 17,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.41667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 8.5, y: 8.14583))
        path.addCurve(to: CGPoint(x: 10.9792, y: 5.66667), control1: CGPoint(x: 9.86921, y: 8.14583), control2: CGPoint(x: 10.9792, y: 7.03587))
        path.addCurve(to: CGPoint(x: 8.5, y: 3.1875), control1: CGPoint(x: 10.9792, y: 4.29746), control2: CGPoint(x: 9.86921, y: 3.1875))
        path.addCurve(to: CGPoint(x: 6.02083, y: 5.66667), control1: CGPoint(x: 7.13079, y: 3.1875), control2: CGPoint(x: 6.02083, y: 4.29746))
        path.addCurve(to: CGPoint(x: 8.5, y: 8.14583), control1: CGPoint(x: 6.02083, y: 7.03587), control2: CGPoint(x: 7.13079, y: 8.14583))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.41667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 3.54167, y: 14.1667))
        path.addCurve(to: CGPoint(x: 8.5, y: 10.2708), control1: CGPoint(x: 4.10833, y: 11.6167), control2: CGPoint(x: 6.02083, y: 10.2708))
        path.addCurve(to: CGPoint(x: 13.4583, y: 14.1667), control1: CGPoint(x: 10.9792, y: 10.2708), control2: CGPoint(x: 12.8917, y: 11.6167))
      }
    ]
  )

  public static let fieldPhone = SmileIcon(
    width: 17,
    height: 17,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.41667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 10.625, y: 1.41667))
        path.addLine(to: CGPoint(x: 6.375, y: 1.41667))
        path.addCurve(to: CGPoint(x: 4.95833, y: 2.83333), control1: CGPoint(x: 5.5926, y: 1.41667), control2: CGPoint(x: 4.95833, y: 2.05093))
        path.addLine(to: CGPoint(x: 4.95833, y: 14.1667))
        path.addCurve(to: CGPoint(x: 6.375, y: 15.5833), control1: CGPoint(x: 4.95833, y: 14.9491), control2: CGPoint(x: 5.5926, y: 15.5833))
        path.addLine(to: CGPoint(x: 10.625, y: 15.5833))
        path.addCurve(to: CGPoint(x: 12.0417, y: 14.1667), control1: CGPoint(x: 11.4074, y: 15.5833), control2: CGPoint(x: 12.0417, y: 14.9491))
        path.addLine(to: CGPoint(x: 12.0417, y: 2.83333))
        path.addCurve(to: CGPoint(x: 10.625, y: 1.41667), control1: CGPoint(x: 12.0417, y: 2.05093), control2: CGPoint(x: 11.4074, y: 1.41667))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.41667, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 7.79167, y: 12.75))
        path.addLine(to: CGPoint(x: 9.20833, y: 12.75))
      }
    ]
  )

  public static let instructions = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.5, y: 16.625))
        path.addCurve(to: CGPoint(x: 16.625, y: 9.5), control1: CGPoint(x: 13.435, y: 16.625), control2: CGPoint(x: 16.625, y: 13.435))
        path.addCurve(to: CGPoint(x: 9.5, y: 2.375), control1: CGPoint(x: 16.625, y: 5.56497), control2: CGPoint(x: 13.435, y: 2.375))
        path.addCurve(to: CGPoint(x: 2.375, y: 9.5), control1: CGPoint(x: 5.56497, y: 2.375), control2: CGPoint(x: 2.375, y: 5.56497))
        path.addCurve(to: CGPoint(x: 9.5, y: 16.625), control1: CGPoint(x: 2.375, y: 13.435), control2: CGPoint(x: 5.56497, y: 16.625))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.5, y: 6.33333))
        path.addLine(to: CGPoint(x: 9.50792, y: 6.33333))
        path.move(to: CGPoint(x: 9.5, y: 8.70833))
        path.addLine(to: CGPoint(x: 9.5, y: 12.6667))
      }
    ]
  )

  public static let licenses = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 6.33333, y: 2.375))
        path.addLine(to: CGPoint(x: 3.95833, y: 2.375))
        path.addCurve(to: CGPoint(x: 2.83875, y: 2.83875), control1: CGPoint(x: 3.53841, y: 2.375), control2: CGPoint(x: 3.13568, y: 2.54181))
        path.addCurve(to: CGPoint(x: 2.375, y: 3.95833), control1: CGPoint(x: 2.54181, y: 3.13568), control2: CGPoint(x: 2.375, y: 3.53841))
        path.addLine(to: CGPoint(x: 2.375, y: 6.33333))
        path.move(to: CGPoint(x: 12.6667, y: 2.375))
        path.addLine(to: CGPoint(x: 15.0417, y: 2.375))
        path.addCurve(to: CGPoint(x: 16.1613, y: 2.83875), control1: CGPoint(x: 15.4616, y: 2.375), control2: CGPoint(x: 15.8643, y: 2.54181))
        path.addCurve(to: CGPoint(x: 16.625, y: 3.95833), control1: CGPoint(x: 16.4582, y: 3.13568), control2: CGPoint(x: 16.625, y: 3.53841))
        path.addLine(to: CGPoint(x: 16.625, y: 6.33333))
        path.move(to: CGPoint(x: 6.33333, y: 16.625))
        path.addLine(to: CGPoint(x: 3.95833, y: 16.625))
        path.addCurve(to: CGPoint(x: 2.83875, y: 16.1613), control1: CGPoint(x: 3.53841, y: 16.625), control2: CGPoint(x: 3.13568, y: 16.4582))
        path.addCurve(to: CGPoint(x: 2.375, y: 15.0417), control1: CGPoint(x: 2.54181, y: 15.8643), control2: CGPoint(x: 2.375, y: 15.4616))
        path.addLine(to: CGPoint(x: 2.375, y: 12.6667))
        path.move(to: CGPoint(x: 12.6667, y: 16.625))
        path.addLine(to: CGPoint(x: 15.0417, y: 16.625))
        path.addCurve(to: CGPoint(x: 16.1613, y: 16.1613), control1: CGPoint(x: 15.4616, y: 16.625), control2: CGPoint(x: 15.8643, y: 16.4582))
        path.addCurve(to: CGPoint(x: 16.625, y: 15.0417), control1: CGPoint(x: 16.4582, y: 15.8643), control2: CGPoint(x: 16.625, y: 15.4616))
        path.addLine(to: CGPoint(x: 16.625, y: 12.6667))
      }
    ]
  )

  public static let plus = SmileIcon(
    width: 960,
    height: 960,
    minX: 0,
    minY: -960,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 440, y: -440))
        path.addLine(to: CGPoint(x: 200, y: -440))
        path.addLine(to: CGPoint(x: 200, y: -520))
        path.addLine(to: CGPoint(x: 440, y: -520))
        path.addLine(to: CGPoint(x: 440, y: -760))
        path.addLine(to: CGPoint(x: 520, y: -760))
        path.addLine(to: CGPoint(x: 520, y: -520))
        path.addLine(to: CGPoint(x: 760, y: -520))
        path.addLine(to: CGPoint(x: 760, y: -440))
        path.addLine(to: CGPoint(x: 520, y: -440))
        path.addLine(to: CGPoint(x: 520, y: -200))
        path.addLine(to: CGPoint(x: 440, y: -200))
        path.addLine(to: CGPoint(x: 440, y: -440))
        path.closeSubpath()
      }
    ]
  )

  public static let preview = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 15.0417, y: 3.95833))
        path.addLine(to: CGPoint(x: 3.95833, y: 3.95833))
        path.addCurve(to: CGPoint(x: 2.375, y: 5.54167), control1: CGPoint(x: 3.08388, y: 3.95833), control2: CGPoint(x: 2.375, y: 4.66722))
        path.addLine(to: CGPoint(x: 2.375, y: 13.4583))
        path.addCurve(to: CGPoint(x: 3.95833, y: 15.0417), control1: CGPoint(x: 2.375, y: 14.3328), control2: CGPoint(x: 3.08388, y: 15.0417))
        path.addLine(to: CGPoint(x: 15.0417, y: 15.0417))
        path.addCurve(to: CGPoint(x: 16.625, y: 13.4583), control1: CGPoint(x: 15.9161, y: 15.0417), control2: CGPoint(x: 16.625, y: 14.3328))
        path.addLine(to: CGPoint(x: 16.625, y: 5.54167))
        path.addCurve(to: CGPoint(x: 15.0417, y: 3.95833), control1: CGPoint(x: 16.625, y: 4.66722), control2: CGPoint(x: 15.9161, y: 3.95833))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.5, y: 11.875))
        path.addCurve(to: CGPoint(x: 11.875, y: 9.5), control1: CGPoint(x: 10.8117, y: 11.875), control2: CGPoint(x: 11.875, y: 10.8117))
        path.addCurve(to: CGPoint(x: 9.5, y: 7.125), control1: CGPoint(x: 11.875, y: 8.18832), control2: CGPoint(x: 10.8117, y: 7.125))
        path.addCurve(to: CGPoint(x: 7.125, y: 9.5), control1: CGPoint(x: 8.18832, y: 7.125), control2: CGPoint(x: 7.125, y: 8.18832))
        path.addCurve(to: CGPoint(x: 9.5, y: 11.875), control1: CGPoint(x: 7.125, y: 10.8117), control2: CGPoint(x: 8.18832, y: 11.875))
        path.closeSubpath()
      }
    ]
  )

  public static let privacy = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.5, y: 2.375))
        path.addLine(to: CGPoint(x: 15.0417, y: 4.75))
        path.addLine(to: CGPoint(x: 15.0417, y: 9.5))
        path.addCurve(to: CGPoint(x: 9.5, y: 16.625), control1: CGPoint(x: 15.0417, y: 12.6667), control2: CGPoint(x: 12.6667, y: 15.0417))
        path.addCurve(to: CGPoint(x: 3.95833, y: 9.5), control1: CGPoint(x: 6.33333, y: 15.0417), control2: CGPoint(x: 3.95833, y: 12.6667))
        path.addLine(to: CGPoint(x: 3.95833, y: 4.75))
        path.addLine(to: CGPoint(x: 9.5, y: 2.375))
        path.closeSubpath()
      }
    ]
  )

  public static let productMark = SmileIcon(
    width: 960,
    height: 960,
    minX: 0,
    minY: -960,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 160, y: -80))
        path.addQuadCurve(to: CGPoint(x: 103.5, y: -103.5), control: CGPoint(x: 127, y: -80))
        path.addQuadCurve(to: CGPoint(x: 80, y: -160), control: CGPoint(x: 80, y: -127))
        path.addLine(to: CGPoint(x: 80, y: -600))
        path.addQuadCurve(to: CGPoint(x: 103.5, y: -656.5), control: CGPoint(x: 80, y: -633))
        path.addQuadCurve(to: CGPoint(x: 160, y: -680), control: CGPoint(x: 127, y: -680))
        path.addLine(to: CGPoint(x: 360, y: -680))
        path.addLine(to: CGPoint(x: 360, y: -800))
        path.addQuadCurve(to: CGPoint(x: 383.5, y: -856.5), control: CGPoint(x: 360, y: -833))
        path.addQuadCurve(to: CGPoint(x: 440, y: -880), control: CGPoint(x: 407, y: -880))
        path.addLine(to: CGPoint(x: 520, y: -880))
        path.addQuadCurve(to: CGPoint(x: 576.5, y: -856.5), control: CGPoint(x: 553, y: -880))
        path.addQuadCurve(to: CGPoint(x: 600, y: -800), control: CGPoint(x: 600, y: -833))
        path.addLine(to: CGPoint(x: 600, y: -680))
        path.addLine(to: CGPoint(x: 800, y: -680))
        path.addQuadCurve(to: CGPoint(x: 856.5, y: -656.5), control: CGPoint(x: 833, y: -680))
        path.addQuadCurve(to: CGPoint(x: 880, y: -600), control: CGPoint(x: 880, y: -633))
        path.addLine(to: CGPoint(x: 880, y: -160))
        path.addQuadCurve(to: CGPoint(x: 856.5, y: -103.5), control: CGPoint(x: 880, y: -127))
        path.addQuadCurve(to: CGPoint(x: 800, y: -80), control: CGPoint(x: 833, y: -80))
        path.addLine(to: CGPoint(x: 160, y: -80))
        path.closeSubpath()
        path.move(to: CGPoint(x: 160, y: -160))
        path.addLine(to: CGPoint(x: 800, y: -160))
        path.addLine(to: CGPoint(x: 800, y: -600))
        path.addLine(to: CGPoint(x: 600, y: -600))
        path.addQuadCurve(to: CGPoint(x: 576.5, y: -543.5), control: CGPoint(x: 600, y: -567))
        path.addQuadCurve(to: CGPoint(x: 520, y: -520), control: CGPoint(x: 553, y: -520))
        path.addLine(to: CGPoint(x: 440, y: -520))
        path.addQuadCurve(to: CGPoint(x: 383.5, y: -543.5), control: CGPoint(x: 407, y: -520))
        path.addQuadCurve(to: CGPoint(x: 360, y: -600), control: CGPoint(x: 360, y: -567))
        path.addLine(to: CGPoint(x: 160, y: -600))
        path.addLine(to: CGPoint(x: 160, y: -160))
        path.closeSubpath()
        path.move(to: CGPoint(x: 240, y: -240))
        path.addLine(to: CGPoint(x: 480, y: -240))
        path.addLine(to: CGPoint(x: 480, y: -258))
        path.addQuadCurve(to: CGPoint(x: 470.5, y: -289.5), control: CGPoint(x: 480, y: -275))
        path.addQuadCurve(to: CGPoint(x: 444, y: -312), control: CGPoint(x: 461, y: -304))
        path.addQuadCurve(to: CGPoint(x: 403.5, y: -325.5), control: CGPoint(x: 424, y: -321))
        path.addQuadCurve(to: CGPoint(x: 360, y: -330), control: CGPoint(x: 383, y: -330))
        path.addQuadCurve(to: CGPoint(x: 316.5, y: -325.5), control: CGPoint(x: 337, y: -330))
        path.addQuadCurve(to: CGPoint(x: 276, y: -312), control: CGPoint(x: 296, y: -321))
        path.addQuadCurve(to: CGPoint(x: 249.5, y: -289.5), control: CGPoint(x: 259, y: -304))
        path.addQuadCurve(to: CGPoint(x: 240, y: -258), control: CGPoint(x: 240, y: -275))
        path.addLine(to: CGPoint(x: 240, y: -240))
        path.closeSubpath()
        path.move(to: CGPoint(x: 560, y: -300))
        path.addLine(to: CGPoint(x: 720, y: -300))
        path.addLine(to: CGPoint(x: 720, y: -360))
        path.addLine(to: CGPoint(x: 560, y: -360))
        path.addLine(to: CGPoint(x: 560, y: -300))
        path.closeSubpath()
        path.move(to: CGPoint(x: 402.5, y: -377.5))
        path.addQuadCurve(to: CGPoint(x: 420, y: -420), control: CGPoint(x: 420, y: -395))
        path.addQuadCurve(to: CGPoint(x: 402.5, y: -462.5), control: CGPoint(x: 420, y: -445))
        path.addQuadCurve(to: CGPoint(x: 360, y: -480), control: CGPoint(x: 385, y: -480))
        path.addQuadCurve(to: CGPoint(x: 317.5, y: -462.5), control: CGPoint(x: 335, y: -480))
        path.addQuadCurve(to: CGPoint(x: 300, y: -420), control: CGPoint(x: 300, y: -445))
        path.addQuadCurve(to: CGPoint(x: 317.5, y: -377.5), control: CGPoint(x: 300, y: -395))
        path.addQuadCurve(to: CGPoint(x: 360, y: -360), control: CGPoint(x: 335, y: -360))
        path.addQuadCurve(to: CGPoint(x: 402.5, y: -377.5), control: CGPoint(x: 385, y: -360))
        path.closeSubpath()
        path.move(to: CGPoint(x: 560, y: -420))
        path.addLine(to: CGPoint(x: 720, y: -420))
        path.addLine(to: CGPoint(x: 720, y: -480))
        path.addLine(to: CGPoint(x: 560, y: -480))
        path.addLine(to: CGPoint(x: 560, y: -420))
        path.closeSubpath()
        path.move(to: CGPoint(x: 440, y: -600))
        path.addLine(to: CGPoint(x: 520, y: -600))
        path.addLine(to: CGPoint(x: 520, y: -800))
        path.addLine(to: CGPoint(x: 440, y: -800))
        path.addLine(to: CGPoint(x: 440, y: -600))
        path.closeSubpath()
        path.move(to: CGPoint(x: 480, y: -380))
        path.closeSubpath()
      }
    ]
  )

  public static let products = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.83333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 2.625, y: 8.75))
        path.addLine(to: CGPoint(x: 10.5, y: 2.625))
        path.addLine(to: CGPoint(x: 18.375, y: 8.75))
        path.addLine(to: CGPoint(x: 18.375, y: 16.625))
        path.addCurve(to: CGPoint(x: 17.8624, y: 17.8624), control1: CGPoint(x: 18.375, y: 17.0891), control2: CGPoint(x: 18.1906, y: 17.5342))
        path.addCurve(to: CGPoint(x: 16.625, y: 18.375), control1: CGPoint(x: 17.5342, y: 18.1906), control2: CGPoint(x: 17.0891, y: 18.375))
        path.addLine(to: CGPoint(x: 13.125, y: 18.375))
        path.addLine(to: CGPoint(x: 13.125, y: 13.125))
        path.addLine(to: CGPoint(x: 7.875, y: 13.125))
        path.addLine(to: CGPoint(x: 7.875, y: 18.375))
        path.addLine(to: CGPoint(x: 4.375, y: 18.375))
        path.addCurve(to: CGPoint(x: 3.13756, y: 17.8624), control1: CGPoint(x: 3.91087, y: 18.375), control2: CGPoint(x: 3.46575, y: 18.1906))
        path.addCurve(to: CGPoint(x: 2.625, y: 16.625), control1: CGPoint(x: 2.80937, y: 17.5342), control2: CGPoint(x: 2.625, y: 17.0891))
        path.addLine(to: CGPoint(x: 2.625, y: 8.75))
        path.closeSubpath()
      }
    ]
  )

  public static let scanGlyph = SmileIcon(
    width: 279,
    height: 280,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 6, round: true), opacity: 0.45) { path in
        path.move(to: CGPoint(x: 58.125, y: 140))
        path.addLine(to: CGPoint(x: 220.875, y: 140))
      },
      SmileIconPart(stroke: .stroke(width: 6, round: true), opacity: 0.45) { path in
        path.move(to: CGPoint(x: 34.875, y: 81.6667))
        path.addLine(to: CGPoint(x: 34.875, y: 58.3333))
        path.addCurve(to: CGPoint(x: 41.6848, y: 41.8342), control1: CGPoint(x: 34.875, y: 52.1449), control2: CGPoint(x: 37.3245, y: 46.21))
        path.addCurve(to: CGPoint(x: 58.125, y: 35), control1: CGPoint(x: 46.045, y: 37.4583), control2: CGPoint(x: 51.9587, y: 35))
        path.addLine(to: CGPoint(x: 81.375, y: 35))
      },
      SmileIconPart(stroke: .stroke(width: 6, round: true), opacity: 0.45) { path in
        path.move(to: CGPoint(x: 34.875, y: 198.333))
        path.addLine(to: CGPoint(x: 34.875, y: 221.667))
        path.addCurve(to: CGPoint(x: 41.6848, y: 238.166), control1: CGPoint(x: 34.875, y: 227.855), control2: CGPoint(x: 37.3245, y: 233.79))
        path.addCurve(to: CGPoint(x: 58.125, y: 245), control1: CGPoint(x: 46.045, y: 242.542), control2: CGPoint(x: 51.9587, y: 245))
        path.addLine(to: CGPoint(x: 81.375, y: 245))
      },
      SmileIconPart(stroke: .stroke(width: 6, round: true), opacity: 0.45) { path in
        path.move(to: CGPoint(x: 197.625, y: 35))
        path.addLine(to: CGPoint(x: 220.875, y: 35))
        path.addCurve(to: CGPoint(x: 237.315, y: 41.8342), control1: CGPoint(x: 227.041, y: 35), control2: CGPoint(x: 232.955, y: 37.4583))
        path.addCurve(to: CGPoint(x: 244.125, y: 58.3333), control1: CGPoint(x: 241.675, y: 46.21), control2: CGPoint(x: 244.125, y: 52.1449))
        path.addLine(to: CGPoint(x: 244.125, y: 81.6667))
      },
      SmileIconPart(stroke: .stroke(width: 6, round: true), opacity: 0.45) { path in
        path.move(to: CGPoint(x: 197.625, y: 245))
        path.addLine(to: CGPoint(x: 220.875, y: 245))
        path.addCurve(to: CGPoint(x: 237.315, y: 238.166), control1: CGPoint(x: 227.041, y: 245), control2: CGPoint(x: 232.955, y: 242.542))
        path.addCurve(to: CGPoint(x: 244.125, y: 221.667), control1: CGPoint(x: 241.675, y: 233.79), control2: CGPoint(x: 244.125, y: 227.855))
        path.addLine(to: CGPoint(x: 244.125, y: 198.333))
      }
    ]
  )

  public static let settingScenarios = SmileIcon(
    width: 960,
    height: 960,
    minX: 0,
    minY: -960,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 440, y: -120))
        path.addLine(to: CGPoint(x: 440, y: -360))
        path.addLine(to: CGPoint(x: 520, y: -360))
        path.addLine(to: CGPoint(x: 520, y: -280))
        path.addLine(to: CGPoint(x: 840, y: -280))
        path.addLine(to: CGPoint(x: 840, y: -200))
        path.addLine(to: CGPoint(x: 520, y: -200))
        path.addLine(to: CGPoint(x: 520, y: -120))
        path.addLine(to: CGPoint(x: 440, y: -120))
        path.closeSubpath()
        path.move(to: CGPoint(x: 120, y: -200))
        path.addLine(to: CGPoint(x: 120, y: -280))
        path.addLine(to: CGPoint(x: 360, y: -280))
        path.addLine(to: CGPoint(x: 360, y: -200))
        path.addLine(to: CGPoint(x: 120, y: -200))
        path.closeSubpath()
        path.move(to: CGPoint(x: 280, y: -360))
        path.addLine(to: CGPoint(x: 280, y: -440))
        path.addLine(to: CGPoint(x: 120, y: -440))
        path.addLine(to: CGPoint(x: 120, y: -520))
        path.addLine(to: CGPoint(x: 280, y: -520))
        path.addLine(to: CGPoint(x: 280, y: -600))
        path.addLine(to: CGPoint(x: 360, y: -600))
        path.addLine(to: CGPoint(x: 360, y: -360))
        path.addLine(to: CGPoint(x: 280, y: -360))
        path.closeSubpath()
        path.move(to: CGPoint(x: 440, y: -440))
        path.addLine(to: CGPoint(x: 440, y: -520))
        path.addLine(to: CGPoint(x: 840, y: -520))
        path.addLine(to: CGPoint(x: 840, y: -440))
        path.addLine(to: CGPoint(x: 440, y: -440))
        path.closeSubpath()
        path.move(to: CGPoint(x: 600, y: -600))
        path.addLine(to: CGPoint(x: 600, y: -840))
        path.addLine(to: CGPoint(x: 680, y: -840))
        path.addLine(to: CGPoint(x: 680, y: -760))
        path.addLine(to: CGPoint(x: 840, y: -760))
        path.addLine(to: CGPoint(x: 840, y: -680))
        path.addLine(to: CGPoint(x: 680, y: -680))
        path.addLine(to: CGPoint(x: 680, y: -600))
        path.addLine(to: CGPoint(x: 600, y: -600))
        path.closeSubpath()
        path.move(to: CGPoint(x: 120, y: -680))
        path.addLine(to: CGPoint(x: 120, y: -760))
        path.addLine(to: CGPoint(x: 520, y: -760))
        path.addLine(to: CGPoint(x: 520, y: -680))
        path.addLine(to: CGPoint(x: 120, y: -680))
        path.closeSubpath()
      }
    ]
  )

  public static let settings = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.83333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 10.5, y: 13.125))
        path.addCurve(to: CGPoint(x: 13.125, y: 10.5), control1: CGPoint(x: 11.9497, y: 13.125), control2: CGPoint(x: 13.125, y: 11.9497))
        path.addCurve(to: CGPoint(x: 10.5, y: 7.875), control1: CGPoint(x: 13.125, y: 9.05025), control2: CGPoint(x: 11.9497, y: 7.875))
        path.addCurve(to: CGPoint(x: 7.875, y: 10.5), control1: CGPoint(x: 9.05025, y: 7.875), control2: CGPoint(x: 7.875, y: 9.05025))
        path.addCurve(to: CGPoint(x: 10.5, y: 13.125), control1: CGPoint(x: 7.875, y: 11.9497), control2: CGPoint(x: 9.05025, y: 13.125))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.83333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 16.625, y: 10.5))
        path.addCurve(to: CGPoint(x: 16.5375, y: 9.625), control1: CGPoint(x: 16.6168, y: 10.2066), control2: CGPoint(x: 16.5876, y: 9.91419))
        path.addLine(to: CGPoint(x: 18.2875, y: 8.3125))
        path.addLine(to: CGPoint(x: 16.5375, y: 5.3375))
        path.addLine(to: CGPoint(x: 14.525, y: 6.2125))
        path.addCurve(to: CGPoint(x: 13.0375, y: 5.3375), control1: CGPoint(x: 14.0729, y: 5.85209), control2: CGPoint(x: 13.5721, y: 5.5575))
        path.addLine(to: CGPoint(x: 12.775, y: 3.15))
        path.addLine(to: CGPoint(x: 9.1, y: 3.15))
        path.addLine(to: CGPoint(x: 8.8375, y: 5.3375))
        path.addCurve(to: CGPoint(x: 7.35, y: 6.2125), control1: CGPoint(x: 8.30286, y: 5.5575), control2: CGPoint(x: 7.80205, y: 5.85209))
        path.addLine(to: CGPoint(x: 5.3375, y: 5.3375))
        path.addLine(to: CGPoint(x: 3.5875, y: 8.3125))
        path.addLine(to: CGPoint(x: 5.25, y: 9.625))
        path.addCurve(to: CGPoint(x: 5.25, y: 11.375), control1: CGPoint(x: 5.16624, y: 10.2053), control2: CGPoint(x: 5.16624, y: 10.7947))
        path.addLine(to: CGPoint(x: 3.5, y: 12.6875))
        path.addLine(to: CGPoint(x: 5.25, y: 15.6625))
        path.addLine(to: CGPoint(x: 7.2625, y: 14.7875))
        path.addCurve(to: CGPoint(x: 8.75, y: 15.6625), control1: CGPoint(x: 7.71455, y: 15.1479), control2: CGPoint(x: 8.21536, y: 15.4425))
        path.addLine(to: CGPoint(x: 9.0125, y: 17.85))
        path.addLine(to: CGPoint(x: 11.8125, y: 17.85))
        path.addLine(to: CGPoint(x: 12.075, y: 15.6625))
        path.addCurve(to: CGPoint(x: 13.5625, y: 14.7875), control1: CGPoint(x: 12.6096, y: 15.4425), control2: CGPoint(x: 13.1104, y: 15.1479))
        path.addLine(to: CGPoint(x: 15.575, y: 15.6625))
        path.addLine(to: CGPoint(x: 17.325, y: 12.6875))
        path.addLine(to: CGPoint(x: 15.575, y: 11.375))
        path.addCurve(to: CGPoint(x: 15.6625, y: 10.5), control1: CGPoint(x: 15.6251, y: 11.0858), control2: CGPoint(x: 15.6543, y: 10.7934))
        path.addLine(to: CGPoint(x: 16.625, y: 10.5))
        path.closeSubpath()
      }
    ]
  )

  public static let smartSelfieAuth = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.625, y: 16.1875))
        path.addCurve(to: CGPoint(x: 16.1875, y: 9.625), control1: CGPoint(x: 13.2494, y: 16.1875), control2: CGPoint(x: 16.1875, y: 13.2494))
        path.addCurve(to: CGPoint(x: 9.625, y: 3.0625), control1: CGPoint(x: 16.1875, y: 6.00063), control2: CGPoint(x: 13.2494, y: 3.0625))
        path.addCurve(to: CGPoint(x: 3.0625, y: 9.625), control1: CGPoint(x: 6.00063, y: 3.0625), control2: CGPoint(x: 3.0625, y: 6.00063))
        path.addCurve(to: CGPoint(x: 9.625, y: 16.1875), control1: CGPoint(x: 3.0625, y: 13.2494), control2: CGPoint(x: 6.00063, y: 16.1875))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 7, y: 9.625))
        path.addLine(to: CGPoint(x: 7.00875, y: 9.625))
        path.move(to: CGPoint(x: 12.25, y: 9.625))
        path.addLine(to: CGPoint(x: 12.2588, y: 9.625))
        path.move(to: CGPoint(x: 7, y: 12.25))
        path.addCurve(to: CGPoint(x: 12.25, y: 12.25), control1: CGPoint(x: 8.4, y: 13.475), control2: CGPoint(x: 10.85, y: 13.475))
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 14.4375, y: 14.875))
        path.addLine(to: CGPoint(x: 16.1875, y: 16.625))
        path.addLine(to: CGPoint(x: 19.25, y: 13.5625))
      }
    ]
  )

  public static let smartSelfieEnrollment = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 10.5, y: 16.625))
        path.addCurve(to: CGPoint(x: 17.5, y: 9.625), control1: CGPoint(x: 14.366, y: 16.625), control2: CGPoint(x: 17.5, y: 13.491))
        path.addCurve(to: CGPoint(x: 10.5, y: 2.625), control1: CGPoint(x: 17.5, y: 5.75901), control2: CGPoint(x: 14.366, y: 2.625))
        path.addCurve(to: CGPoint(x: 3.5, y: 9.625), control1: CGPoint(x: 6.63401, y: 2.625), control2: CGPoint(x: 3.5, y: 5.75901))
        path.addCurve(to: CGPoint(x: 10.5, y: 16.625), control1: CGPoint(x: 3.5, y: 13.491), control2: CGPoint(x: 6.63401, y: 16.625))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 7.875, y: 9.625))
        path.addLine(to: CGPoint(x: 7.88375, y: 9.625))
        path.move(to: CGPoint(x: 13.125, y: 9.625))
        path.addLine(to: CGPoint(x: 13.1338, y: 9.625))
        path.move(to: CGPoint(x: 7.875, y: 12.6875))
        path.addCurve(to: CGPoint(x: 13.125, y: 12.6875), control1: CGPoint(x: 9.3625, y: 14), control2: CGPoint(x: 11.6375, y: 14))
      },
      SmileIconPart(stroke: .stroke(width: 2.16667, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 10.5, y: 1.3125))
        path.addLine(to: CGPoint(x: 10.5, y: 3.9375))
      }
    ]
  )

  public static let smile = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 9.5, y: 15.0417))
        path.addCurve(to: CGPoint(x: 15.8333, y: 8.70833), control1: CGPoint(x: 12.9978, y: 15.0417), control2: CGPoint(x: 15.8333, y: 12.2061))
        path.addCurve(to: CGPoint(x: 9.5, y: 2.375), control1: CGPoint(x: 15.8333, y: 5.21053), control2: CGPoint(x: 12.9978, y: 2.375))
        path.addCurve(to: CGPoint(x: 3.16667, y: 8.70833), control1: CGPoint(x: 6.0022, y: 2.375), control2: CGPoint(x: 3.16667, y: 5.21053))
        path.addCurve(to: CGPoint(x: 9.5, y: 15.0417), control1: CGPoint(x: 3.16667, y: 12.2061), control2: CGPoint(x: 6.0022, y: 15.0417))
        path.closeSubpath()
      },
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 7.125, y: 8.70833))
        path.addLine(to: CGPoint(x: 7.13292, y: 8.70833))
        path.move(to: CGPoint(x: 11.875, y: 8.70833))
        path.addLine(to: CGPoint(x: 11.8829, y: 8.70833))
        path.move(to: CGPoint(x: 7.125, y: 11.4792))
        path.addCurve(to: CGPoint(x: 11.875, y: 11.4792), control1: CGPoint(x: 8.47083, y: 12.6667), control2: CGPoint(x: 10.5292, y: 12.6667))
      }
    ]
  )

  public static let support = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 3.16667, y: 9.5))
        path.addCurve(to: CGPoint(x: 5.02166, y: 5.02166), control1: CGPoint(x: 3.16667, y: 7.8203), control2: CGPoint(x: 3.83393, y: 6.20939))
        path.addCurve(to: CGPoint(x: 9.5, y: 3.16667), control1: CGPoint(x: 6.20939, y: 3.83393), control2: CGPoint(x: 7.8203, y: 3.16667))
        path.addCurve(to: CGPoint(x: 13.9783, y: 5.02166), control1: CGPoint(x: 11.1797, y: 3.16667), control2: CGPoint(x: 12.7906, y: 3.83393))
        path.addCurve(to: CGPoint(x: 15.8333, y: 9.5), control1: CGPoint(x: 15.1661, y: 6.20939), control2: CGPoint(x: 15.8333, y: 7.8203))
        path.addCurve(to: CGPoint(x: 13.9783, y: 13.9783), control1: CGPoint(x: 15.8333, y: 11.1797), control2: CGPoint(x: 15.1661, y: 12.7906))
        path.addCurve(to: CGPoint(x: 9.5, y: 15.8333), control1: CGPoint(x: 12.7906, y: 15.1661), control2: CGPoint(x: 11.1797, y: 15.8333))
        path.addLine(to: CGPoint(x: 3.16667, y: 15.8333))
        path.addLine(to: CGPoint(x: 3.16667, y: 9.5))
        path.closeSubpath()
      }
    ]
  )

  public static let terms = SmileIcon(
    width: 19,
    height: 19,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.58333, round: false), opacity: 1) { path in
        path.move(to: CGPoint(x: 3.95833, y: 2.375))
        path.addLine(to: CGPoint(x: 15.0417, y: 2.375))
        path.addLine(to: CGPoint(x: 15.0417, y: 16.625))
        path.addLine(to: CGPoint(x: 9.5, y: 14.25))
        path.addLine(to: CGPoint(x: 3.95833, y: 16.625))
        path.addLine(to: CGPoint(x: 3.95833, y: 2.375))
        path.closeSubpath()
      }
    ]
  )

  public static let tokenScan = SmileIcon(
    width: 16,
    height: 16,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.83333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 2.66667, y: 5.33333))
        path.addLine(to: CGPoint(x: 2.66667, y: 4))
        path.addCurve(to: CGPoint(x: 3.05719, y: 3.05719), control1: CGPoint(x: 2.66667, y: 3.64638), control2: CGPoint(x: 2.80714, y: 3.30724))
        path.addCurve(to: CGPoint(x: 4, y: 2.66667), control1: CGPoint(x: 3.30724, y: 2.80714), control2: CGPoint(x: 3.64638, y: 2.66667))
        path.addLine(to: CGPoint(x: 5.33333, y: 2.66667))
        path.move(to: CGPoint(x: 10.6667, y: 2.66667))
        path.addLine(to: CGPoint(x: 12, y: 2.66667))
        path.addCurve(to: CGPoint(x: 12.9428, y: 3.05719), control1: CGPoint(x: 12.3536, y: 2.66667), control2: CGPoint(x: 12.6928, y: 2.80714))
        path.addCurve(to: CGPoint(x: 13.3333, y: 4), control1: CGPoint(x: 13.1929, y: 3.30724), control2: CGPoint(x: 13.3333, y: 3.64638))
        path.addLine(to: CGPoint(x: 13.3333, y: 5.33333))
        path.move(to: CGPoint(x: 13.3333, y: 10.6667))
        path.addLine(to: CGPoint(x: 13.3333, y: 12))
        path.addCurve(to: CGPoint(x: 12.9428, y: 12.9428), control1: CGPoint(x: 13.3333, y: 12.3536), control2: CGPoint(x: 13.1929, y: 12.6928))
        path.addCurve(to: CGPoint(x: 12, y: 13.3333), control1: CGPoint(x: 12.6928, y: 13.1929), control2: CGPoint(x: 12.3536, y: 13.3333))
        path.addLine(to: CGPoint(x: 10.6667, y: 13.3333))
        path.move(to: CGPoint(x: 5.33333, y: 13.3333))
        path.addLine(to: CGPoint(x: 4, y: 13.3333))
        path.addCurve(to: CGPoint(x: 3.05719, y: 12.9428), control1: CGPoint(x: 3.64638, y: 13.3333), control2: CGPoint(x: 3.30724, y: 13.1929))
        path.addCurve(to: CGPoint(x: 2.66667, y: 12), control1: CGPoint(x: 2.80714, y: 12.6928), control2: CGPoint(x: 2.66667, y: 12.3536))
        path.addLine(to: CGPoint(x: 2.66667, y: 10.6667))
      },
      SmileIconPart(stroke: .stroke(width: 1.83333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 2.66667, y: 8))
        path.addLine(to: CGPoint(x: 13.3333, y: 8))
      }
    ]
  )

  public static let torch = SmileIcon(
    width: 960,
    height: 960,
    minX: 0,
    minY: -960,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 320, y: -80))
        path.addLine(to: CGPoint(x: 320, y: -520))
        path.addLine(to: CGPoint(x: 240, y: -640))
        path.addLine(to: CGPoint(x: 240, y: -880))
        path.addLine(to: CGPoint(x: 720, y: -880))
        path.addLine(to: CGPoint(x: 720, y: -640))
        path.addLine(to: CGPoint(x: 640, y: -520))
        path.addLine(to: CGPoint(x: 640, y: -80))
        path.addLine(to: CGPoint(x: 320, y: -80))
        path.closeSubpath()
        path.move(to: CGPoint(x: 437.5, y: -357.5))
        path.addQuadCurve(to: CGPoint(x: 420, y: -400), control: CGPoint(x: 420, y: -375))
        path.addQuadCurve(to: CGPoint(x: 437.5, y: -442.5), control: CGPoint(x: 420, y: -425))
        path.addQuadCurve(to: CGPoint(x: 480, y: -460), control: CGPoint(x: 455, y: -460))
        path.addQuadCurve(to: CGPoint(x: 522.5, y: -442.5), control: CGPoint(x: 505, y: -460))
        path.addQuadCurve(to: CGPoint(x: 540, y: -400), control: CGPoint(x: 540, y: -425))
        path.addQuadCurve(to: CGPoint(x: 522.5, y: -357.5), control: CGPoint(x: 540, y: -375))
        path.addQuadCurve(to: CGPoint(x: 480, y: -340), control: CGPoint(x: 505, y: -340))
        path.addQuadCurve(to: CGPoint(x: 437.5, y: -357.5), control: CGPoint(x: 455, y: -340))
        path.closeSubpath()
        path.move(to: CGPoint(x: 320, y: -760))
        path.addLine(to: CGPoint(x: 640, y: -760))
        path.addLine(to: CGPoint(x: 640, y: -800))
        path.addLine(to: CGPoint(x: 320, y: -800))
        path.addLine(to: CGPoint(x: 320, y: -760))
        path.closeSubpath()
        path.move(to: CGPoint(x: 640, y: -680))
        path.addLine(to: CGPoint(x: 320, y: -680))
        path.addLine(to: CGPoint(x: 320, y: -664))
        path.addLine(to: CGPoint(x: 400, y: -544))
        path.addLine(to: CGPoint(x: 400, y: -160))
        path.addLine(to: CGPoint(x: 560, y: -160))
        path.addLine(to: CGPoint(x: 560, y: -544))
        path.addLine(to: CGPoint(x: 640, y: -664))
        path.addLine(to: CGPoint(x: 640, y: -680))
        path.closeSubpath()
        path.move(to: CGPoint(x: 480, y: -480))
        path.closeSubpath()
      }
    ]
  )

  public static let trash = SmileIcon(
    width: 960,
    height: 960,
    minX: 0,
    minY: -960,
    parts: [
      SmileIconPart(stroke: .fill, opacity: 1) { path in
        path.move(to: CGPoint(x: 280, y: -120))
        path.addQuadCurve(to: CGPoint(x: 223.5, y: -143.5), control: CGPoint(x: 247, y: -120))
        path.addQuadCurve(to: CGPoint(x: 200, y: -200), control: CGPoint(x: 200, y: -167))
        path.addLine(to: CGPoint(x: 200, y: -720))
        path.addLine(to: CGPoint(x: 160, y: -720))
        path.addLine(to: CGPoint(x: 160, y: -800))
        path.addLine(to: CGPoint(x: 360, y: -800))
        path.addLine(to: CGPoint(x: 360, y: -840))
        path.addLine(to: CGPoint(x: 600, y: -840))
        path.addLine(to: CGPoint(x: 600, y: -800))
        path.addLine(to: CGPoint(x: 800, y: -800))
        path.addLine(to: CGPoint(x: 800, y: -720))
        path.addLine(to: CGPoint(x: 760, y: -720))
        path.addLine(to: CGPoint(x: 760, y: -200))
        path.addQuadCurve(to: CGPoint(x: 736.5, y: -143.5), control: CGPoint(x: 760, y: -167))
        path.addQuadCurve(to: CGPoint(x: 680, y: -120), control: CGPoint(x: 713, y: -120))
        path.addLine(to: CGPoint(x: 280, y: -120))
        path.closeSubpath()
        path.move(to: CGPoint(x: 680, y: -720))
        path.addLine(to: CGPoint(x: 280, y: -720))
        path.addLine(to: CGPoint(x: 280, y: -200))
        path.addLine(to: CGPoint(x: 680, y: -200))
        path.addLine(to: CGPoint(x: 680, y: -720))
        path.closeSubpath()
        path.move(to: CGPoint(x: 360, y: -280))
        path.addLine(to: CGPoint(x: 440, y: -280))
        path.addLine(to: CGPoint(x: 440, y: -640))
        path.addLine(to: CGPoint(x: 360, y: -640))
        path.addLine(to: CGPoint(x: 360, y: -280))
        path.closeSubpath()
        path.move(to: CGPoint(x: 520, y: -280))
        path.addLine(to: CGPoint(x: 600, y: -280))
        path.addLine(to: CGPoint(x: 600, y: -640))
        path.addLine(to: CGPoint(x: 520, y: -640))
        path.addLine(to: CGPoint(x: 520, y: -280))
        path.closeSubpath()
        path.move(to: CGPoint(x: 280, y: -720))
        path.addLine(to: CGPoint(x: 280, y: -200))
        path.addLine(to: CGPoint(x: 280, y: -720))
        path.closeSubpath()
      }
    ]
  )

  public static let verifications = SmileIcon(
    width: 21,
    height: 21,
    minX: 0,
    minY: 0,
    parts: [
      SmileIconPart(stroke: .stroke(width: 1.83333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 7.875, y: 5.25))
        path.addLine(to: CGPoint(x: 17.5, y: 5.25))
        path.move(to: CGPoint(x: 7.875, y: 10.5))
        path.addLine(to: CGPoint(x: 17.5, y: 10.5))
        path.move(to: CGPoint(x: 7.875, y: 15.75))
        path.addLine(to: CGPoint(x: 17.5, y: 15.75))
      },
      SmileIconPart(stroke: .stroke(width: 1.83333, round: true), opacity: 1) { path in
        path.move(to: CGPoint(x: 3.0625, y: 5.25))
        path.addLine(to: CGPoint(x: 3.9375, y: 6.125))
        path.addLine(to: CGPoint(x: 5.25, y: 4.375))
        path.move(to: CGPoint(x: 3.0625, y: 10.5))
        path.addLine(to: CGPoint(x: 3.9375, y: 11.375))
        path.addLine(to: CGPoint(x: 5.25, y: 9.625))
        path.move(to: CGPoint(x: 3.0625, y: 15.75))
        path.addLine(to: CGPoint(x: 3.9375, y: 16.625))
        path.addLine(to: CGPoint(x: 5.25, y: 14.875))
      }
    ]
  )
}
