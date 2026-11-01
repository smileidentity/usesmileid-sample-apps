import SwiftUI

/// The cold-start intro: "SmileID" unrolls out of the logo's lock, which shuts and opens again on the way; a tap skips to `onFinished`.
public struct LaunchIntroScreen: View {
  private let onFinished: () -> Void

  @State private var start = Date()
  @State private var finished = false

  public init(onFinished: @escaping () -> Void) {
    self.onFinished = onFinished
  }

  public var body: some View {
    TimelineView(.animation) { timeline in
      LaunchIntroFrame(progress: timeline.date.timeIntervalSince(start) / LaunchIntroTimeline.duration)
    }
    .contentShape(Rectangle())
    .onTapGesture(perform: finish)
    .accessibilityIdentifier(UseSmileIDSampleTestIds.launchIntro)
    .task {
      start = Date()
      try? await Task.sleep(for: .seconds(LaunchIntroTimeline.duration))
      finish()
    }
  }

  /// Once only, whether the timeline ran out or a tap came first.
  private func finish() {
    guard !finished else { return }
    finished = true
    onFinished()
  }
}

/// One frame of the intro at a fixed `progress`, always on the dark scheme whatever the device's.
struct LaunchIntroFrame: View {
  let progress: Double

  private static let paths = UseSmileIDSampleLogo.Paths()

  var body: some View {
    let colors = UseSmileIDSampleColors.dark
    let pose = LaunchIntroTimeline.pose(progress)
    Canvas { context, size in
      LaunchIntroDrawing(ink: colors.textTitle, accent: colors.decorative.orange, paths: Self.paths)
        .draw(pose, in: context, size: size)
    }
    .background(colors.background)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(UseSmileIDSampleStrings.launchIntroLabel)
  }
}

/// Where every part of the logo is at one instant; `shackleLock` runs from 0, the logo's own open shackle, to 1, seated on the body.
struct LaunchIntroPose: Equatable {
  var markAlpha: Double
  var markScale: Double
  var shackleLock: Double
  var shackleLift: Double
  var clickSquash: Double
  var ringProgress: Double
  var wordmarkReveal: Double

  /// The logo as the brand draws it, which is where every intro ends.
  static let rest = LaunchIntroPose(
    markAlpha: 1,
    markScale: 1,
    shackleLock: 0,
    shackleLift: 0,
    clickSquash: 0,
    ringProgress: 1,
    wordmarkReveal: 1
  )
}

/// The intro's choreography in milliseconds, as a pure function of progress so goldens can stop it on any frame.
enum LaunchIntroTimeline {
  static let durationMillis: Double = 2800

  /// The whole intro in seconds, as SwiftUI counts time.
  static let duration: TimeInterval = durationMillis / 1000

  /// The logo drawn in full size, its shackle still in the brand's open position.
  static let appeared = 500 / durationMillis

  /// The shackle seated on the body, with the name part-way out.
  static let locked = 1150 / durationMillis

  private static let markStartScale = 0.85
  private static let hopHeight = 1.6
  private static let unlockClickStrength = 0.6

  static func pose(_ progress: Double) -> LaunchIntroPose {
    let ms = min(max(progress, 0), 1) * durationMillis
    let lock = phase(ms, 600, 1000, LaunchIntroEasing.fastOutSlowIn)
    let unlock = phase(ms, 1300, 1700, LaunchIntroEasing.fastOutSlowIn)
    return LaunchIntroPose(
      markAlpha: phase(ms, 0, 350, LaunchIntroEasing.linearOutSlowIn),
      markScale: lerp(markStartScale, 1, phase(ms, 0, 450, LaunchIntroEasing.fastOutSlowIn)),
      shackleLock: lock * (1 - unlock),
      shackleLift: hopHeight * (arc(lock) + arc(unlock)),
      clickSquash: bump(phase(ms, 1000, 1250, LaunchIntroEasing.linear))
        + unlockClickStrength * bump(phase(ms, 1700, 1950, LaunchIntroEasing.linear)),
      ringProgress: phase(ms, 1000, 1500, LaunchIntroEasing.linearOutSlowIn),
      wordmarkReveal: phase(ms, 350, 1600, LaunchIntroEasing.linearOutSlowIn)
    )
  }

  private static func phase(_ ms: Double, _ start: Double, _ end: Double, _ easing: (Double) -> Double) -> Double {
    easing(min(max((ms - start) / (end - start), 0), 1))
  }

  /// A hop's height along its flight: zero on the ground at both ends, never below it.
  private static func arc(_ flight: Double) -> Double {
    flight > 0 && flight < 1 ? sin(flight * .pi) : 0
  }

  /// A landing's squash, decaying to nothing so the body settles back to its own shape.
  private static func bump(_ time: Double) -> Double {
    (1 - time) * arc(time)
  }
}

/// The platform-neutral curves the four apps share, so every intro moves alike.
enum LaunchIntroEasing {
  static func linear(_ fraction: Double) -> Double {
    fraction
  }

  /// cubic-bezier(0.4, 0, 0.2, 1).
  static func fastOutSlowIn(_ fraction: Double) -> Double {
    cubicBezier(0.4, 0, 0.2, 1, fraction)
  }

  /// cubic-bezier(0, 0, 0.2, 1).
  static func linearOutSlowIn(_ fraction: Double) -> Double {
    cubicBezier(0, 0, 0.2, 1, fraction)
  }

  /// The curve's height where its x reaches `fraction`; x rises monotonically, so bisection always converges.
  private static func cubicBezier(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ fraction: Double) -> Double {
    guard fraction > 0 else { return 0 }
    guard fraction < 1 else { return 1 }
    var low = 0.0
    var high = 1.0
    var t = fraction
    for _ in 0..<Self.solveIterations {
      if bezier(x1, x2, t) < fraction {
        low = t
      } else {
        high = t
      }
      t = (low + high) / 2
    }
    return bezier(y1, y2, t)
  }

  private static func bezier(_ first: Double, _ second: Double, _ t: Double) -> Double {
    let inverse = 1 - t
    return 3 * first * inverse * inverse * t + 3 * second * inverse * t * t + t * t * t
  }

  private static let solveIterations = 40
}

/// The intro's draw code, in the logo's own viewport units.
private struct LaunchIntroDrawing {
  let ink: Color
  let accent: Color
  let paths: UseSmileIDSampleLogo.Paths

  private static let logoWidthFraction = 0.62
  private static let squashY = 0.14
  private static let squashX = 0.07
  private static let ringStartRadius = 4.0
  private static let ringEndRadius = 9.0
  private static let ringStroke = 0.16
  private static let ringAlpha = 0.45
  private static let wordmarkSlide = 2.0
  private static let clipBleed = 0.5

  func draw(_ pose: LaunchIntroPose, in context: GraphicsContext, size: CGSize) {
    let logo = UseSmileIDSampleLogo.self
    let logoScale = size.width * Self.logoWidthFraction / logo.bounds.width
    // Centres what is visible so far, so the name pushes the lock aside as it unrolls.
    let visibleRight = lerp(logo.markBounds.maxX, logo.bounds.maxX, pose.wordmarkReveal)
    let focus = CGPoint(x: (logo.markBounds.minX + visibleRight) / 2, y: logo.bounds.midY)

    var canvas = context
    canvas.translateBy(x: size.width / 2 - focus.x * logoScale, y: size.height / 2 - focus.y * logoScale)
    canvas.scaleBy(x: logoScale, y: logoScale)

    var mark = canvas
    mark.scale(pose.markScale, pose.markScale, about: CGPoint(x: logo.markBounds.midX, y: logo.markBounds.midY))
    drawLock(pose, in: mark)

    guard pose.wordmarkReveal > 0 else { return }
    let words = logo.wordmarkBounds
    let start = words.minX - Self.clipBleed
    var reveal = canvas
    reveal.clip(to: Path(CGRect(
      x: start,
      y: logo.bounds.minY - Self.clipBleed,
      width: lerp(start, words.maxX + Self.clipBleed, pose.wordmarkReveal) - start,
      height: logo.bounds.height + Self.clipBleed * 2
    )))
    reveal.translateBy(x: -Self.wordmarkSlide * (1 - pose.wordmarkReveal), y: 0)
    reveal.fill(paths.wordmark, with: .color(ink))
  }

  private func drawLock(_ pose: LaunchIntroPose, in context: GraphicsContext) {
    let logo = UseSmileIDSampleLogo.self
    if pose.ringProgress > 0, pose.ringProgress < 1 {
      let radius = lerp(Self.ringStartRadius, Self.ringEndRadius, pose.ringProgress)
      let center = CGPoint(x: logo.bodyBase.x, y: logo.markBounds.midY)
      var ring = context
      ring.opacity = (1 - pose.ringProgress) * Self.ringAlpha
      ring.stroke(
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
        with: .color(accent),
        lineWidth: Self.ringStroke
      )
    }
    let bodyScaleY = 1 - Self.squashY * pose.clickSquash
    let bodyScaleX = 1 + Self.squashX * pose.clickSquash
    var body = context
    body.opacity = pose.markAlpha
    body.scale(bodyScaleX, bodyScaleY, about: logo.bodyBase)
    body.fill(paths.body, with: .color(ink))

    // The shackle rides the body's top edge, so it sinks with the squash instead of floating above it.
    let seatDrop = (logo.bodyBase.y - logo.bodyTop) * (1 - bodyScaleY)
    var shackle = context
    shackle.opacity = pose.markAlpha
    shackle.translateBy(x: logo.lockedShackleShift * pose.shackleLock, y: seatDrop - pose.shackleLift)
    shackle.fill(paths.shackle, with: .color(accent))
  }
}

private extension GraphicsContext {
  /// Scales about `pivot` rather than the origin, as Compose's `scale(x, y, pivot)` does.
  mutating func scale(_ x: Double, _ y: Double, about pivot: CGPoint) {
    translateBy(x: pivot.x, y: pivot.y)
    scaleBy(x: x, y: y)
    translateBy(x: -pivot.x, y: -pivot.y)
  }
}

private func lerp(_ start: Double, _ stop: Double, _ fraction: Double) -> Double {
  (1 - fraction) * start + fraction * stop
}
