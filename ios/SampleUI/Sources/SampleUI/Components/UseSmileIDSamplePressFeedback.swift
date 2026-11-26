import SwiftUI

/// The scale a product card draws at: smaller while held, unless it is disabled or motion is reduced.
func useSmileIDSamplePressScale(pressed: Bool, enabled: Bool, reduceMotion: Bool) -> CGFloat {
  pressed && enabled && !reduceMotion ? pressedScale : 1
}

/// The opacity a held card draws at when reduced motion stops the scale, so a press still shows.
func useSmileIDSamplePressOpacity(pressed: Bool, enabled: Bool, reduceMotion: Bool) -> Double {
  pressed && enabled && reduceMotion ? reducedMotionPressedOpacity : 1
}

private let pressedScale: CGFloat = 0.97
private let reducedMotionPressedOpacity = 0.7

/// A plain button that shrinks while held, easing back on release, and dims instead under reduced motion.
struct UseSmileIDSamplePressScaleStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(useSmileIDSamplePressScale(pressed: configuration.isPressed, enabled: enabled, reduceMotion: reduceMotion))
      .opacity(useSmileIDSamplePressOpacity(pressed: configuration.isPressed, enabled: enabled, reduceMotion: reduceMotion))
      .animation(.easeOut(duration: SmileMotion.durationFast), value: configuration.isPressed)
  }
}
