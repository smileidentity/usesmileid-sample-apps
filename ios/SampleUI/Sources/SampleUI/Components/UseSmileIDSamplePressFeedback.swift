import SwiftUI

/// The scale a product card draws at: smaller while held, unless it is disabled or motion is reduced.
func useSmileIDSamplePressScale(pressed: Bool, enabled: Bool, reduceMotion: Bool) -> CGFloat {
  pressed && enabled && !reduceMotion ? pressedScale : 1
}

private let pressedScale: CGFloat = 0.97

/// A plain button that shrinks while held, easing back on release.
struct UseSmileIDSamplePressScaleStyle: ButtonStyle {
  @Environment(\.isEnabled) private var enabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(useSmileIDSamplePressScale(pressed: configuration.isPressed, enabled: enabled, reduceMotion: reduceMotion))
      .animation(.easeOut(duration: SmileMotion.durationFast), value: configuration.isPressed)
  }
}

/// A selection tick for a chip or tab: played only when the tap picks something new.
@MainActor
enum UseSmileIDSampleSelectionTick {
  /// Plays [tick] unless [alreadySelected], then runs [action].
  static func pick(alreadySelected: Bool, tick: @MainActor () -> Void = play, action: () -> Void) {
    if !alreadySelected {
      tick()
    }
    action()
  }

  /// UIKit's selection feedback, the tick a picker plays.
  static func play() {
    UISelectionFeedbackGenerator().selectionChanged()
  }
}
