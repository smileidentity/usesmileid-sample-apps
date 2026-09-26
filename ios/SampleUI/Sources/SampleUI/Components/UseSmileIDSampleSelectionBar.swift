import SwiftUI

/// The select-mode checkbox. Circular rather than a rounded square, which is the design's correction.
public struct UseSmileIDSampleSelectionCheckbox: View {
  @Binding private var checked: Bool
  private let testId: String?

  @ScaledMetric(relativeTo: .body) private var size: CGFloat = SmileSpacing.sizeIconLg
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(checked: Binding<Bool>, testId: String? = nil) {
    _checked = checked
    self.testId = testId
  }

  public var body: some View {
    Button { checked.toggle() } label: {
      Circle()
        .fill(checked ? colors.primary : colors.surface)
        .overlay(
          // A 2pt ring in border-strong: color.border is far too pale to read as a control.
          Circle().strokeBorder(checked ? colors.primary : smileBorderStrong, lineWidth: SmileSpacing.borderWidthThick)
        )
        .overlay(checked ? UseSmileIDSampleIcon(SmileIcons.check, tint: colors.onPrimary, size: 11) : nil)
        .frame(width: size, height: size)
        // max(), or a scaled size past the target turns the compensating inset into outward padding.
        .frame(minWidth: max(Self.target, size), minHeight: max(Self.target, size))
        .contentShape(Rectangle())
        .padding(-max(0, (Self.target - size) / 2))
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(checked ? [.isButton, .isSelected] : .isButton)
    .useSmileIDSampleTestId(testId)
  }

  private static let target: CGFloat = 44
}

/// Replaces the nav bar in select mode; the count is its own node, so a flow asserts equality rather than parsing prose.
public struct UseSmileIDSampleSelectionBar: View {
  private let selectedCount: Int
  private let onRemove: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(selectedCount: Int, onRemove: @escaping () -> Void) {
    self.selectedCount = selectedCount
    self.onRemove = onRemove
  }

  public var body: some View {
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
          counts
          action
        }
      } else {
        HStack(spacing: SmileSpacing.spacingSm) {
          counts
          action
        }
      }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingSm)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(colors.surface)
    // The one container carrying an id: `.contain` keeps the count and action addressable.
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.selectionBar)
    // A top edge only, so a border is wrong — that would outline all four sides.
    .overlay(alignment: .top) {
      Rectangle().fill(colors.border).frame(height: SmileSpacing.borderWidthHairline)
    }
  }

  private var counts: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
      UseSmileIDSampleText(
        "\(selectedCount) selected",
        style: UseSmileIDSampleTheme.type.textStyleBodyStrong.with(size: 14)
      )
      .foregroundColor(colors.textTitle)
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.selectionCount)
      UseSmileIDSampleText(
        selectedCount == 0 ? "Tap rows to select" : "Tap \"Hide from List\" to confirm",
        style: UseSmileIDSampleTheme.type.textStyleBodySm.with(size: 11.5)
      )
      .foregroundColor(colors.textMuted)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var action: some View {
    Button(action: onRemove) {
      HStack(spacing: SmileSpacing.spacingXs) {
        UseSmileIDSampleIcon(SmileIcons.trash, tint: colors.badge.errorText, size: SmileSpacing.sizeIconSm)
        UseSmileIDSampleText("Hide from List", style: UseSmileIDSampleTheme.type.textStyleBodyStrong.with(size: 13.5))
          .foregroundColor(colors.badge.errorText)
      }
      .padding(.horizontal, SmileSpacing.spacingMd)
      .padding(.vertical, SmileSpacing.spacingXs)
      .frame(minHeight: SmileSpacing.space40)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.pill, style: .continuous)
          .fill(colors.badge.errorBackground)
      )
    }
    .buttonStyle(.plain)
    .disabled(selectedCount == 0)
    // Dimmed rather than recoloured, so a disabled action still reads as the strong one.
    .opacity(selectedCount == 0 ? Self.disabledOpacity : 1)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.selectionRemove)
  }

  private static let disabledOpacity: Double = 0.45
}
