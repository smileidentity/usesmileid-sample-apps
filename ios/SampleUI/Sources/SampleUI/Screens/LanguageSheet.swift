import SwiftUI

/// System, then each shipped language under its own name; a pick applies at the next launch.
public struct LanguageSheet: View {
  private let selected: UseSmileIDSampleLanguage
  private let deviceLanguages: [String]
  /// True while the pick differs from the running language.
  private let pending: Bool
  private let onSelect: (UseSmileIDSampleLanguage) -> Void
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    selected: UseSmileIDSampleLanguage,
    deviceLanguages: [String],
    pending: Bool,
    onSelect: @escaping (UseSmileIDSampleLanguage) -> Void
  ) {
    self.selected = selected
    self.deviceLanguages = deviceLanguages
    self.pending = pending
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: UseSmileIDSampleStrings.languageTitle, testId: UseSmileIDSampleTestIds.languageSheet) {
      ForEach(UseSmileIDSampleLanguage.allCases, id: \.self) { language in
        UseSmileIDSampleOptionRow(
          label: language.label(deviceLanguages: deviceLanguages),
          selected: language == selected,
          testId: UseSmileIDSampleTestIds.languageOption(language.rawValue),
          onTap: { onSelect(language) }
        )
      }
      if pending {
        UseSmileIDSampleText(UseSmileIDSampleStrings.languageAppliesOnRelaunch, style: UseSmileIDSampleTheme.type.textStyleCaption)
          .foregroundColor(colors.textMuted)
          .padding(.horizontal, SmileSpacing.spacingMd)
          .padding(.vertical, SmileSpacing.spacingXs)
      }
    }
  }
}
