import SwiftUI

/// The sheet's chrome: a title and scrolling content, always the platform's full-height card — the Compose twin's content-height variant has no counterpart here.
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
  private let testId: String?
  private let onClose: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(title: String, testId: String? = nil, onClose: @escaping () -> Void) {
    self.title = title
    self.testId = testId
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
        .useSmileIDSampleTestId(testId)
      Spacer(minLength: 0)
    }
    .padding(.vertical, SmileSpacing.spacingXs)
  }

  private static var gap: CGFloat {
    10
  }
}

/// The full-height sheet: a back header instead of a plain title, for the long picker lists.
public struct UseSmileIDSampleFullHeightBottomSheet<Content: View>: View {
  private let title: String
  private let testId: String?
  private let onClose: () -> Void
  private let content: Content

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    title: String,
    testId: String? = nil,
    onClose: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.testId = testId
    self.onClose = onClose
    self.content = content()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      UseSmileIDSampleSheetHeader(title: title, testId: testId, onClose: onClose)
        .padding(.horizontal, Self.margin)
      ScrollView {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
          content
        }
        .padding(.horizontal, Self.margin)
        .padding(.bottom, SmileSpacing.spacingLg)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(colors.surface.ignoresSafeArea())
  }

  private static var margin: CGFloat {
    SmileSpacing.space20
  }
}
