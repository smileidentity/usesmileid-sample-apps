import SwiftUI

/// Wraps a row in a trailing swipe that reveals Hide. Not `List`'s `swipeActions`: a `List`'s own
/// backdrop cannot be cleared on the iOS 15 floor, and it would replace the screen background.
public struct UseSmileIDSampleSwipeAction<Content: View>: View {
  private let onRemove: () -> Void
  private let content: Content

  /// Rests at zero, so there is no half-open row: a release either commits or snaps back.
  @GestureState private var drag: CGFloat = 0
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(onRemove: @escaping () -> Void, @ViewBuilder content: () -> Content) {
    self.onRemove = onRemove
    self.content = content()
  }

  public var body: some View {
    ZStack(alignment: .trailing) {
      backdrop
      content
        .offset(x: drag)
        .animation(.interactiveSpring(), value: drag)
    }
    // High priority, or the row's button swallows the drag; a tap still reaches it, needing no distance.
    .highPriorityGesture(swipe)
  }

  private var swipe: some Gesture {
    DragGesture(minimumDistance: Self.minimumDistance)
      .updating($drag) { value, state, _ in
        // Trailing only, and only once the drag is more sideways than down: the list still scrolls.
        let sideways = abs(value.translation.width) > abs(value.translation.height)
        state = sideways ? min(0, value.translation.width) : 0
      }
      .onEnded { value in
        // The settled translation, so a redraw mid-gesture cannot remove the row twice.
        if -value.translation.width >= Self.revealWidth {
          onRemove()
        }
      }
  }

  private var backdrop: some View {
    VStack(spacing: SmileSpacing.spacingXxs) {
      UseSmileIDSampleIcon(SmileIcons.trash, tint: colors.errorFill, size: SmileSpacing.sizeIconMd)
      UseSmileIDSampleText("Hide", style: UseSmileIDSampleTheme.type.textStyleCaption)
        .foregroundColor(colors.errorFill)
    }
    .frame(width: Self.revealWidth)
  }

  /// 80 in the design; space64 plus a gap is the nearest the scale reaches.
  private static var revealWidth: CGFloat {
    SmileSpacing.space64 + SmileSpacing.spacingMd
  }

  /// Enough of a head start that a vertical drag reaches the scroll view instead.
  private static var minimumDistance: CGFloat {
    SmileSpacing.spacingMd
  }
}
