import SwiftUI

/// The sheet search field; the glyph is the SF Symbol, the shared icon set having no magnifier.
public struct UseSmileIDSampleSearchField: View {
  @Binding private var query: String
  private let placeholder: String
  private let testId: String?

  @FocusState private var focused: Bool
  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(query: Binding<String>, placeholder: String = "", testId: String? = nil) {
    _query = query
    self.placeholder = placeholder
    self.testId = testId
  }

  public var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(colors.search.icon)

      ZStack(alignment: .leading) {
        if query.isEmpty {
          UseSmileIDSampleText(placeholder, style: UseSmileIDSampleTheme.type.searchFont)
            .foregroundColor(colors.search.placeholder)
        }
        TextField("", text: $query)
          .font(UseSmileIDSampleFonts.font(UseSmileIDSampleTheme.type.searchFont))
          .foregroundColor(colors.search.text)
          .accentColor(colors.search.borderFocus)
          .focused($focused)
          .useSmileIDSampleTestId(testId)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingSm)
    .frame(minHeight: minHeight)
    .background(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
        .fill(colors.search.background)
    )
    .overlay(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
        .strokeBorder(
          focused ? colors.search.borderFocus : colors.search.border,
          lineWidth: focused ? SmileSpacing.borderWidthThin : SmileSpacing.borderWidthHairline
        )
    )
  }
}
