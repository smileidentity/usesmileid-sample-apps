import SwiftUI

/// The notices the app ships rather than links to (Apache-2.0 §4).
///
/// A flat list, not the rounded section cards: this screen has no design frame, and two hundred
/// rows inside one card would compose all of them at once.
public struct LicensesScreen: View {
  private let licenses: UseSmileIDSampleLicenses
  private let onBack: () -> Void
  private let onOpenUrl: (String) -> Void

  /// One at a time: two copies of the Apache text at once is a screen nobody can read.
  @State private var expanded: String?

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    licenses: UseSmileIDSampleLicenses,
    onBack: @escaping () -> Void,
    onOpenUrl: @escaping (String) -> Void = { _ in }
  ) {
    self.licenses = licenses
    self.onBack = onBack
    self.onOpenUrl = onOpenUrl
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: "Open-source licenses", onBack: onBack)
      ScrollView {
        if licenses.isEmpty {
          // Generated at build time, so an empty list means the asset did not ship.
          UseSmileIDSampleEmptyState(
            text: "No notices bundled",
            supportingText: "The generated licenses.json is missing from this build",
            testId: UseSmileIDSampleTestIds.licensesEmpty
          )
          .padding(.top, SmileSpacing.spacingXl)
        } else {
          LazyVStack(alignment: .leading, spacing: 0) {
            UseSmileIDSampleSectionLabel("OPEN-SOURCE COMPONENTS — \(licenses.components.count)")
              .padding(.horizontal, SmileSpacing.spacingMd)
              .padding(.vertical, SmileSpacing.spacingXs)
            ForEach(licenses.components, id: \.component) { notice in
              noticeRow(notice)
            }
          }
          .padding(.bottom, SmileSpacing.spacingMd)
        }
      }
    }
    .background(colors.background)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.licensesScreen)
  }

  private func noticeRow(_ notice: UseSmileIDSampleNotice) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      // No leading tile and no chevron: the component is the content, and the row expands.
      UseSmileIDSampleSettingRow(
        title: notice.component,
        supportingText: notice.subtitle,
        testId: UseSmileIDSampleTestIds.licenseRow(notice.component),
        onTap: { expanded = expanded == notice.component ? nil : notice.component }
      )
      if expanded == notice.component {
        expandedLicence(notice)
      }
      UseSmileIDSampleRowDivider()
    }
  }

  /// The licence text where it ships with us, and the page that carries it where it does not.
  @ViewBuilder
  private func expandedLicence(_ notice: UseSmileIDSampleNotice) -> some View {
    UseSmileIDSampleText(
      notice.text ?? "The text ships with the component itself.",
      style: UseSmileIDSampleTheme.type.textStyleCaption
    )
    .foregroundColor(colors.textMuted)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.bottom, SmileSpacing.spacingSm)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.licenseText(notice.component))
    if let url = notice.url, notice.text == nil {
      UseSmileIDSampleSettingRow(
        title: "Open \(notice.licenseName)",
        testId: UseSmileIDSampleTestIds.licenseLink(notice.component),
        onTap: { onOpenUrl(url) }
      )
    }
  }
}
