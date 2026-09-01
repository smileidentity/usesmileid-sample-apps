@testable import SampleUI
import SwiftUI
import XCTest

/// Every U1 primitive in every state `spec/components.json` names, light and dark.
final class UseSmileIDSamplePrimitivesGoldenTest: UseSmileIDSampleGoldenTest {
  func testButtonStates() {
    goldens("button_states") { ButtonStates() }
  }

  func testButtonSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { ButtonStates(loading: true) }
  }

  func testTextInputStates() {
    goldens("text_input_states") { TextInputStates() }
  }

  func testTextInputSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { TextInputStates() }
  }

  func testSearchField() {
    goldens("search_field") { SearchFieldStates() }
  }

  func testStatusBadges() {
    goldens("status_badges") { StatusBadges() }
  }

  func testStatusBadgesSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { StatusBadges() }
  }

  func testAvatars() {
    goldens("avatars") { Avatars() }
  }

  func testSectionLabel() {
    goldens("section_label") { SectionLabels() }
  }

  /// No thumb in this baseline: UISwitch draws it in a layer the offscreen path skips, and the
  /// strategy that captures it needs a host app. The tracks still catch a tint regression.
  func testSwitchStates() {
    goldens("switch_states") { SwitchStates() }
  }

  func testToast() {
    goldens("toast") { Toasts() }
  }

  func testToastSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { Toasts() }
  }

  func testEmptyStates() {
    goldens("empty_states") { EmptyStates() }
  }

  func testEmptyStatesSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { EmptyStates() }
  }
}

/// Both variants `spec/components.json` names: the supporting line only where a reader can act.
private struct EmptyStates: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingLg) {
      UseSmileIDSampleEmptyState(text: "Nothing matches that search")
      UseSmileIDSampleEmptyState(
        text: "No verification here",
        supportingText: "Nothing stored for jobId = job_missing"
      )
    }
  }
}

private struct ButtonStates: View {
  /// Loading is off for the baseline and on for the font-scale predicate, matching the Compose
  /// twin: a spinner's frame zero is a fragile golden, but it lays out fine to assert against.
  var loading = false

  var body: some View {
    VStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleButton(text: "Continue") {}
      UseSmileIDSampleButton(text: "Continue", enabled: false) {}
      if loading {
        UseSmileIDSampleButton(text: "Continue", loading: true) {}
      }
      // The longest product label on the narrowest card it appears on.
      UseSmileIDSampleButton(text: "SmartSelfie Authentication") {}
    }
  }
}

private struct TextInputStates: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleTextInput(value: .constant(""), placeholder: "ID number")
      UseSmileIDSampleTextInput(value: .constant("A012345678"), placeholder: "ID number")
      UseSmileIDSampleTextInput(
        value: .constant("not-an-email"),
        placeholder: "Email",
        isError: true,
        errorMessage: "Enter a valid email address"
      )
      UseSmileIDSampleTextInput(value: .constant("Disabled"), enabled: false)
      UseSmileIDSampleTextInput(value: .constant("secret-token"), masked: true)
      UseSmileIDSampleTextInput(value: .constant("Ada"), placeholder: "First name") {
        Image(systemName: "person")
      }
    }
  }
}

private struct SearchFieldStates: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleSearchField(query: .constant(""), placeholder: "Search countries")
      UseSmileIDSampleSearchField(query: .constant("Nigeria"), placeholder: "Search countries")
    }
  }
}

private struct StatusBadges: View {
  var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      ForEach(UseSmileIDSampleStatus.allCases, id: \.self) { status in
        UseSmileIDSampleStatusBadge(status: status)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct Avatars: View {
  var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      // One per profile hue, so a reordered list shows up here.
      ForEach(0..<smileProfileHues.count, id: \.self) { index in
        UseSmileIDSampleAvatar(
          initials: "P\(index + 1)",
          containerColor: useSmileIDSampleAvatarColor(profileIndex: index)
        )
      }
      UseSmileIDSampleAvatar(initials: "")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SectionLabels: View {
  var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleSectionLabel("AUTHENTICATION")
      UseSmileIDSampleSectionLabel("YOUR DETAILS")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SwitchStates: View {
  var body: some View {
    HStack(spacing: SmileSpacing.spacingLg) {
      UseSmileIDSampleSwitch(isOn: .constant(true))
      UseSmileIDSampleSwitch(isOn: .constant(false))
      UseSmileIDSampleSwitch(isOn: .constant(true), enabled: false)
      UseSmileIDSampleSwitch(isOn: .constant(false), enabled: false)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct Toasts: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleToast(message: "1 verification hidden from App list")
      // The copy and the ids deliberately disagree: the store method is remove, the label is Hide.
      UseSmileIDSampleToast(message: "1 verification hidden from App list", actionLabel: "Undo") {}
      UseSmileIDSampleToast(message: "Kobo Bank created", actionLabel: "Make active") {}
    }
  }
}
