import SwiftUI

/// Builds the generic document that "Capture as: Generic document" hands the SDK. Nothing is kept until Done.
public struct GenericDocumentSheet: View {
  private let onDone: (UseSmileIDSampleGenericDocument) -> Void
  @State private var draft: UseSmileIDSampleGenericDocument

  public init(initial: UseSmileIDSampleGenericDocument, onDone: @escaping (UseSmileIDSampleGenericDocument) -> Void) {
    _draft = State(initialValue: initial)
    self.onDone = onDone
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: UseSmileIDSampleStrings.genericDocumentTitle, testId: UseSmileIDSampleTestIds.genericDocumentSheet) {
      UseSmileIDSampleSectionLabel(UseSmileIDSampleStrings.genericDocumentDisplayName)
      UseSmileIDSampleTextInput(
        value: $draft.displayName,
        placeholder: UseSmileIDSampleStrings.genericDocumentDefaultName,
        testId: UseSmileIDSampleTestIds.genericDocumentName
      )
      UseSmileIDSampleSettingRow(title: UseSmileIDSampleStrings.genericDocumentBackSide, supportingText: UseSmileIDSampleStrings.genericDocumentBackSideHint) {
        EmptyView()
      } trailing: {
        UseSmileIDSampleSwitch(isOn: $draft.hasBackSide, testId: UseSmileIDSampleTestIds.genericDocumentBackSide)
      }
      UseSmileIDSampleSectionLabel(UseSmileIDSampleStrings.genericDocumentOrientation)
      chips(UseSmileIDSampleDocumentOrientation.allCases, selected: draft.orientation, label: \.label) {
        draft.orientation = $0
      } testId: {
        UseSmileIDSampleTestIds.genericDocumentOrientation($0.rawValue)
      }
      UseSmileIDSampleSectionLabel(UseSmileIDSampleStrings.genericDocumentAspectRatio)
      chips(UseSmileIDSampleAspectRatio.allCases, selected: draft.aspectRatio, label: \.label) {
        draft.aspectRatio = $0
      } testId: {
        UseSmileIDSampleTestIds.genericDocumentAspectRatio($0.rawValue)
      }
      UseSmileIDSampleButton(text: UseSmileIDSampleStrings.commonDone, testId: UseSmileIDSampleTestIds.genericDocumentDone) {
        var done = draft
        let trimmed = done.displayName.trimmingCharacters(in: .whitespaces)
        done.displayName = trimmed.isEmpty ? UseSmileIDSampleStrings.genericDocumentDefaultName : trimmed
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
