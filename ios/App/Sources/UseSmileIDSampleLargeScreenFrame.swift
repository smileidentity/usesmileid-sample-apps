import SampleUI
import SwiftUI

/// The largest iPhone's frame the app's own screens draw in on a large screen, from `spec/large-screen-frame.json`.
enum UseSmileIDSampleLargeScreen {
  /// The shorter side a large screen starts at.
  static let minSide: CGFloat = 600

  /// The iPhone 18 Pro Max's screen, the SDK's own large-screen frame.
  static let frame = CGSize(width: 440, height: 956)

  /// The app's size in a `window` whose safe area is `safeArea`: the frame, each side the safe area's where shorter, on a large screen; nil on a phone.
  static func frameSize(window: CGSize, safeArea: CGSize) -> CGSize? {
    guard min(window.width, window.height) >= minSide else { return nil }
    return CGSize(width: min(max(safeArea.width, 0), frame.width), height: min(max(safeArea.height, 0), frame.height))
  }
}

/// Draws `content` on a large screen as the largest iPhone shows it, centred on the screen background; a phone, or `framed` false, fills the window.
struct UseSmileIDSampleLargeScreenFrame<Content: View>: View {
  @Environment(\.useSmileIDSampleColors) private var colors
  let framed: Bool
  @ViewBuilder let content: Content

  var body: some View {
    GeometryReader { geometry in
      let insets = geometry.safeAreaInsets
      let window = CGSize(
        width: geometry.size.width + insets.leading + insets.trailing,
        height: geometry.size.height + insets.top + insets.bottom
      )
      let frame = framed ? UseSmileIDSampleLargeScreen.frameSize(window: window, safeArea: geometry.size) : nil
      content
        .frame(width: frame?.width, height: frame?.height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((frame == nil ? Color.clear : colors.background).ignoresSafeArea())
    }
  }
}
