import SwiftUI

/// Filled is back and the torch, tonal the trailing action, destructive the delete.
public enum UseSmileIDSampleTopAppBarEmphasis: Sendable {
  case filled
  case tonal
  case destructive
}

/// One circular 40pt app-bar control. The label lives here because the glyph is decorative.
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

/// The pushed-screen app bar; no safe-area inset, which the presenting container owns and a sheet would double.
public struct UseSmileIDSampleTopAppBar<Action: View>: View {
  private let title: String
  private let backLabel: String
  private let testId: String?
  private let onBack: () -> Void
  private let action: Action

  @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 40
  @ScaledMetric(relativeTo: .body) private var actionWidth: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

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
    // Stacks once type grows: between two controls that scale with it the title wraps letter by letter.
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
          HStack(spacing: SmileSpacing.spacingXs) {
            backButton
            Spacer(minLength: 0)
            trailing
          }
          titleText(alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      } else {
        HStack(spacing: SmileSpacing.spacingXs) {
          backButton
          titleText(alignment: .center)
            .frame(maxWidth: .infinity)
          trailing
        }
      }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.bottom, SmileSpacing.spacingXs)
    .frame(minHeight: rowHeight)
    // Its ideal height, not what is left over: compressed, the wrapping title ellipsises.
    .fixedSize(horizontal: false, vertical: true)
    .useSmileIDSampleTestId(testId)
  }

  private var backButton: some View {
    UseSmileIDSampleTopAppBarButton(label: backLabel, emphasis: .filled, action: onBack) { tint in
      UseSmileIDSampleIcon(SmileIcons.arrowBack, tint: tint, size: SmileSpacing.sizeIconMd)
    }
  }

  /// Wraps rather than truncates: an ellipsised title is the clipping the predicate forbids.
  private func titleText(alignment: TextAlignment) -> some View {
    UseSmileIDSampleText(title, style: UseSmileIDSampleTheme.type.textStyleTitle.with(size: 15))
      .foregroundColor(colors.textTitle)
      .multilineTextAlignment(alignment)
  }

  /// Holds the action's width even with none, so the title sits identically either way.
  @ViewBuilder
  private var trailing: some View {
    if Action.self == EmptyView.self {
      Color.clear.frame(width: actionWidth, height: 1)
    } else {
      action
    }
  }
}
