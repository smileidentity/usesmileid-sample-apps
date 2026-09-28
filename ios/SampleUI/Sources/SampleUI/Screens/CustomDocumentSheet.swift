import SwiftUI

/// Builds the generic document that "Capture as: Custom" hands the SDK. Nothing is kept until Done.
public struct CustomDocumentSheet: View {
  private let onDone: (UseSmileIDSampleCustomDocument) -> Void
  @State private var draft: UseSmileIDSampleCustomDocument

  public init(initial: UseSmileIDSampleCustomDocument, onDone: @escaping (UseSmileIDSampleCustomDocument) -> Void) {
    _draft = State(initialValue: initial)
    self.onDone = onDone
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Custom document", testId: UseSmileIDSampleTestIds.customDocumentSheet) {
      UseSmileIDSampleSectionLabel("DISPLAY NAME")
      UseSmileIDSampleTextInput(
        value: $draft.displayName,
        placeholder: "Document",
        testId: UseSmileIDSampleTestIds.customDocumentName
      )
      UseSmileIDSampleSettingRow(title: "Back side", supportingText: "Capture the back after the front") {
        EmptyView()
      } trailing: {
        UseSmileIDSampleSwitch(isOn: $draft.hasBackSide, testId: UseSmileIDSampleTestIds.customDocumentBackSide)
      }
      UseSmileIDSampleSectionLabel("ORIENTATION")
      chips(UseSmileIDSampleDocumentOrientation.allCases, selected: draft.orientation, label: \.label) {
        draft.orientation = $0
      } testId: {
        UseSmileIDSampleTestIds.customDocumentOrientation($0.rawValue)
      }
      UseSmileIDSampleSectionLabel("ASPECT RATIO")
      chips(UseSmileIDSampleAspectRatio.allCases, selected: draft.aspectRatio, label: \.label) {
        draft.aspectRatio = $0
      } testId: {
        UseSmileIDSampleTestIds.customDocumentAspectRatio($0.rawValue)
      }
      UseSmileIDSampleButton(text: "Done", testId: UseSmileIDSampleTestIds.customDocumentDone) {
        var done = draft
        let trimmed = done.displayName.trimmingCharacters(in: .whitespaces)
        done.displayName = trimmed.isEmpty ? "Document" : trimmed
        onDone(done)
      }
    }
  }

  /// A wrapping row of chips, one per value; `LazyVGrid` stands in for the flow layout iOS 15 lacks.
  private func chips<Value: Hashable>(
    _ values: [Value],
    selected: Value,
    label: KeyPath<Value, String>,
    onSelect: @escaping (Value) -> Void,
    testId: @escaping (Value) -> String
  ) -> some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), alignment: .leading)], alignment: .leading) {
      ForEach(values, id: \.self) { value in
        UseSmileIDSampleFilterChip(
          label: value[keyPath: label],
          count: nil,
          selected: value == selected,
          testId: testId(value),
          onTap: { onSelect(value) }
        )
      }
    }
  }
}
