import SwiftUI

/// The sheet's own chrome: a title and the content, scrolling so enlarged type cannot push a CTA
/// out of reach.
///
/// There is no partial-height variant. `presentationDetents` is iOS 16 and this package's floor is
/// 15, so every sheet is the platform's full-height card and the system supplies the grabber. The
/// Compose twin distinguishes a content-height sheet from a full-height one; hand-rolling that here
/// would reproduce Android's presentation instead of the platform's, which the porting rules call a
/// defect even when it looks identical.
public struct UseSmileIDSampleBottomSheet<Content: View>: View {
  private let title: String?
  private let testId: String?
  private let content: Content

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(title: String? = nil, testId: String? = nil, @ViewBuilder content: () -> Content) {
    self.title = title
    self.testId = testId
    self.content = content()
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
        if let title {
          UseSmileIDSampleText(title, style: titleStyle)
            .foregroundColor(colors.textTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .useSmileIDSampleTestId(testId)
        }
        content
      }
      .padding(.horizontal, Self.margin)
      .padding(.top, SmileSpacing.spacingLg)
      .padding(.bottom, SmileSpacing.spacingLg)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(colors.surface.ignoresSafeArea())
  }

  private var titleStyle: SmileTextStyle {
    UseSmileIDSampleTheme.type.textStyleHeadingSection.with(weight: 700)
  }

  private static var margin: CGFloat {
    SmileSpacing.space20
  }
}

/// The sheet header the long picker lists use: a back control beside the title.
public struct UseSmileIDSampleSheetHeader: View {
  private let title: String
  private let onClose: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(title: String, onClose: @escaping () -> Void) {
    self.title = title
    self.onClose = onClose
  }

  public var body: some View {
    HStack(spacing: Self.gap) {
      UseSmileIDSampleTopAppBarButton(label: "Close \(title)", emphasis: .filled, action: onClose) { tint in
        UseSmileIDSampleIcon(SmileIcons.arrowBack, tint: tint, size: SmileSpacing.sizeIconMd)
      }
      UseSmileIDSampleText(title, style: UseSmileIDSampleTheme.type.textStyleTitle)
        .foregroundColor(colors.textTitle)
        .lineLimit(1)
      Spacer(minLength: 0)
    }
    .padding(.vertical, SmileSpacing.spacingXs)
  }

  private static var gap: CGFloat {
    10
  }
}
