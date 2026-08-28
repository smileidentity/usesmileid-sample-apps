import SwiftUI

/// Filled is the dark control used for back and the Scan token torch; tonal is the light trailing
/// action; destructive is the soft-red delete.
public enum UseSmileIDSampleTopAppBarEmphasis: Sendable {
  case filled
  case tonal
  case destructive
}

/// One circular 40pt app-bar control.
///
/// A `Button` rather than a tappable shape, so it keeps the platform's own hit-testing and its
/// VoiceOver button trait; the label is supplied here because the glyph inside is decorative.
public struct UseSmileIDSampleTopAppBarButton<Glyph: View>: View {
  private let label: String
  private let emphasis: UseSmileIDSampleTopAppBarEmphasis
  private let testId: String?
  private let action: () -> Void
  private let glyph: (Color) -> Glyph

  @ScaledMetric(relativeTo: .body) private var size: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    label: String,
    emphasis: UseSmileIDSampleTopAppBarEmphasis = .tonal,
    testId: String? = nil,
    action: @escaping () -> Void,
    @ViewBuilder glyph: @escaping (Color) -> Glyph
  ) {
    self.label = label
    self.emphasis = emphasis
    self.testId = testId
    self.action = action
    self.glyph = glyph
  }

  public var body: some View {
    Button(action: action) {
      glyph(pair.tint)
        .frame(width: size, height: size)
        .background(Circle().fill(pair.container))
    }
    .accessibilityLabel(label)
    .useSmileIDSampleTestId(testId)
  }

  private var pair: (container: Color, tint: Color) {
    switch emphasis {
    case .filled: (colors.textTitle, colors.textInverse)
    case .tonal: (colors.surfaceTile, colors.textTitle)
    case .destructive: (colors.badge.errorBackground, colors.badge.errorText)
    }
  }
}

/// The pushed-screen app bar: a filled circular back control, a title, and an optional action.
///
/// The safe-area inset is NOT applied here. On iOS the presenting container already owns it, and a
/// component that adds its own would double it inside a sheet — the mirror of the mistake the
/// Compose twin's toast made by re-applying an inset the host had already handled.
public struct UseSmileIDSampleTopAppBar<Action: View>: View {
  private let title: String
  private let backLabel: String
  private let testId: String?
  private let onBack: () -> Void
  private let action: Action

  @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 40
  @ScaledMetric(relativeTo: .body) private var actionWidth: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    title: String,
    backLabel: String = "Back",
    testId: String? = nil,
    onBack: @escaping () -> Void,
    @ViewBuilder action: () -> Action = { EmptyView() }
  ) {
    self.title = title
    self.backLabel = backLabel
    self.testId = testId
    self.onBack = onBack
    self.action = action()
  }

  public var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleTopAppBarButton(label: backLabel, emphasis: .filled, action: onBack) { tint in
        UseSmileIDSampleIcon(SmileIcons.arrowBack, tint: tint, size: SmileSpacing.sizeIconMd)
      }

      // Wraps rather than truncates: ellipsising a title is the clipping the predicate forbids.
      UseSmileIDSampleText(title, style: UseSmileIDSampleTheme.type.textStyleTitle.with(size: 15))
        .foregroundColor(colors.textTitle)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)

      // Holds the action's width even with none, so the title sits identically either way.
      if Action.self == EmptyView.self {
        Color.clear.frame(width: actionWidth, height: 1)
      } else {
        action
      }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.bottom, SmileSpacing.spacingXs)
    .frame(minHeight: rowHeight)
    .useSmileIDSampleTestId(testId)
  }
}
