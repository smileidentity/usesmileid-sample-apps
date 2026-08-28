@testable import SampleUI
import SwiftUI
import XCTest

final class UseSmileIDSampleCompositeGoldenTest: UseSmileIDSampleGoldenTest {
  func testTopAppBar() {
    goldens("top_app_bar") { TopAppBars() }
  }

  func testTopAppBarSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { TopAppBars() }
  }

  func testDataFieldRows() {
    goldens("data_field_rows") { DataFieldRows() }
  }

  func testDataFieldRowsSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { DataFieldRows() }
  }

  func testSettingRows() {
    goldens("setting_rows") { SettingRows() }
  }

  func testSettingRowsSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { SettingRows() }
  }

  func testProfileRows() {
    goldens("profile_rows") { ProfileRows() }
  }

  func testOptionRows() {
    goldens("option_rows") { OptionRows() }
  }

  func testSelectTriggers() {
    goldens("select_triggers") { SelectTriggers() }
  }

  func testSelectTriggersSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { SelectTriggers() }
  }

  func testKeyValueEditRows() {
    goldens("key_value_edit_rows") { KeyValueEditRows() }
  }

  func testKeyValueEditRowsSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { KeyValueEditRows() }
  }
}

private struct TopAppBars: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleTopAppBar(title: "Verification details", onBack: {})
      UseSmileIDSampleTopAppBar(title: "Scan token", onBack: {}) {
        UseSmileIDSampleTopAppBarButton(label: "Torch", action: {}) { tint in
          UseSmileIDSampleIcon(SmileIcons.torch, tint: tint, size: SmileSpacing.sizeIconMd)
        }
      }
      UseSmileIDSampleTopAppBar(title: "Verification details", onBack: {}) {
        UseSmileIDSampleTopAppBarButton(label: "Delete", emphasis: .destructive, action: {}) { tint in
          UseSmileIDSampleIcon(SmileIcons.trash, tint: tint, size: SmileSpacing.sizeIconMd)
        }
      }
    }
  }
}

private struct DataFieldRows: View {
  var body: some View {
    UseSmileIDSampleSectionSurface(label: "DETAILS") {
      UseSmileIDSampleDataFieldRow(label: "Job ID", value: "job-8f21c4de", onCopy: {})
      UseSmileIDSampleRowDivider()
      UseSmileIDSampleDataFieldRow(label: "Submitted", value: "12 Aug 2026, 14:03")
      UseSmileIDSampleRowDivider()
      UseSmileIDSampleDataFieldRow(label: "Status", value: "200 OK", valueColor: .green)
      UseSmileIDSampleRowDivider()
      UseSmileIDSampleDataFieldRow(label: "Environment", value: "sandbox")
    }
  }
}

private struct SettingRows: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleSectionSurface(label: "CAPTURE") {
        UseSmileIDSampleSettingRow(title: "Agent mode", supportingText: "Capture on someone else's behalf") {
          UseSmileIDSampleIcon(SmileIcons.agent, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
        } trailing: {
          UseSmileIDSampleSwitch(isOn: .constant(true))
        }
        UseSmileIDSampleRowDivider()
        UseSmileIDSampleSettingRow(title: "Consent screen", onTap: {}) {
          UseSmileIDSampleIcon(SmileIcons.consent, tint: colors.textTitle, size: SmileSpacing.sizeIconMd)
        } trailing: {
          UseSmileIDSampleSettingRowChevron()
        }
        UseSmileIDSampleRowDivider()
        UseSmileIDSampleSettingRow(title: "Licences")
      }
      UseSmileIDSampleDestructiveRow(text: "Sign out") {}
    }
  }
}

private struct ProfileRows: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleProfileRow(
        organisation: "Kobo Bank",
        supportingText: "Ada Lovelace",
        initials: "KB",
        selected: true,
        avatarColor: useSmileIDSampleAvatarColor(profileIndex: 0),
        onTap: {}
      )
      UseSmileIDSampleProfileRow(
        organisation: "Acme Fintech",
        supportingText: "Tap to configure",
        initials: "AF",
        selected: false,
        avatarColor: useSmileIDSampleAvatarColor(profileIndex: 1),
        onTap: {}
      )
    }
  }
}

private struct OptionRows: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingXxs) {
      UseSmileIDSampleOptionRow(label: "Nigeria", leadingText: "🇳🇬", selected: true, onTap: {})
      UseSmileIDSampleOptionRow(label: "Kenya", leadingText: "🇰🇪", selected: false, onTap: {})
      UseSmileIDSampleOptionRow(label: "National ID", selected: false, onTap: {})
    }
  }
}

private struct SelectTriggers: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleSelectTrigger(value: "Nigeria", placeholder: "Select country", onTap: {}) {
        UseSmileIDSampleTriggerEmoji("🇳🇬")
      }
      UseSmileIDSampleSelectTrigger(value: nil, placeholder: "Select country", onTap: {})
      UseSmileIDSampleSelectTrigger(value: nil, placeholder: "Select ID type", enabled: false, onTap: {})
    }
  }
}

private struct KeyValueEditRows: View {
  var body: some View {
    UseSmileIDSampleSectionSurface(label: "YOUR DETAILS") {
      UseSmileIDSampleKeyValueEditRow(label: "First name", value: .constant("Ada"), required: true)
      UseSmileIDSampleRowDivider()
      UseSmileIDSampleKeyValueEditRow(label: "Email", value: .constant(""), placeholder: "Add an email")
      UseSmileIDSampleRowDivider()
      UseSmileIDSampleKeyValueEditRow(label: "Partner ID", value: .constant("1234"), enabled: false)
    }
  }
}
