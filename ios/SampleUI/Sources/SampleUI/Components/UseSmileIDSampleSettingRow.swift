import SwiftUI

/// A settings row: a glyph tile, a title with an optional supporting line, and a trailing control.
public struct UseSmileIDSampleSettingRow<Leading: View, Trailing: View>: View {
  private let title: String
  private let supportingText: String?
  private let testId: String?
  private let onTap: (() -> Void)?
  private let leading: Leading
  private let trailing: Trailing

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = 38
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    title: String,
    supportingText: String? = nil,
    testId: String? = nil,
    onTap: (() -> Void)? = nil,
    @ViewBuilder leading: () -> Leading = { EmptyView() },
    @ViewBuilder trailing: () -> Trailing = { EmptyView() }
  ) {
    self.title = title
    self.supportingText = supportingText
    self.testId = testId
    self.onTap = onTap
    self.leading = leading()
    self.trailing = trailing()
  }

  public var body: some View {
    // A whole-row Button when the row navigates, so the tap target and the VoiceOver trait are the
    // platform's; a plain row otherwise, rather than a button that does nothing.
    if let onTap {
      Button(action: onTap) { row }
        .buttonStyle(.plain)
        .useSmileIDSampleTestId(testId)
    } else {
      row.useSmileIDSampleTestId(testId)
    }
  }

  private var row: some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      if Leading.self != EmptyView.self {
        leading
          .frame(width: tileSize, height: tileSize)
          .background(
            RoundedRectangle(cornerRadius: Self.tileRadius, style: .continuous)
              .fill(colors.surfaceTile)
          )
      }
      VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
        UseSmileIDSampleText(title, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
          .foregroundColor(colors.textTitle)
        if let supportingText {
          UseSmileIDSampleText(supportingText, style: UseSmileIDSampleTheme.type.textStyleCaption)
            .foregroundColor(colors.textMuted)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      trailing
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingSm)
    .frame(minHeight: minHeight)
    .contentShape(Rectangle())
  }

  private static var tileRadius: CGFloat {
    11
  }
}

/// The trailing chevron that says the row pushes a screen.
public struct UseSmileIDSampleSettingRowChevron: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  public init() {}

  public var body: some View {
    UseSmileIDSampleIcon(SmileIcons.chevron, tint: colors.textMuted, size: 14)
  }
}

/// Sign out: full width, centred, in the soft error pair rather than the saturated pill colour.
public struct UseSmileIDSampleDestructiveRow: View {
  private let text: String
  private let testId: String?
  private let action: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(text: String, testId: String? = nil, action: @escaping () -> Void) {
    self.text = text
    self.testId = testId
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      UseSmileIDSampleText(text, style: UseSmileIDSampleTheme.type.textStyleButton)
        .foregroundColor(colors.badge.errorText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, minHeight: SmileSpacing.sizeControlMd)
        .padding(SmileSpacing.spacingSm)
        .background(
          RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
            .fill(colors.surface)
        )
        .overlay(
          RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
            .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
        )
    }
    .buttonStyle(.plain)
    .useSmileIDSampleTestId(testId)
  }
}
