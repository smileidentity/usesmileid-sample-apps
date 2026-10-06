import SwiftUI

/// The document products' picker: the country's supported documents, a standalone sub-type as its own row.
public struct DocumentPickerSheet: View {
  private let country: UseSmileIDSampleCountry?
  private let catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleDocument>
  private let selected: UseSmileIDSampleDocument?
  @Binding private var query: String
  private let onSelect: (UseSmileIDSampleDocument) -> Void
  private let onRetry: () -> Void
  private let onClose: () -> Void

  public init(
    country: UseSmileIDSampleCountry?,
    catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleDocument>,
    selected: UseSmileIDSampleDocument?,
    query: Binding<String>,
    onSelect: @escaping (UseSmileIDSampleDocument) -> Void,
    onRetry: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    self.country = country
    self.catalogue = catalogue
    self.selected = selected
    _query = query
    self.onSelect = onSelect
    self.onRetry = onRetry
    self.onClose = onClose
  }

  public var body: some View {
    UseSmileIDSampleFullHeightBottomSheet(
      title: UseSmileIDSampleStrings.pickerDocumentTitle,
      testId: UseSmileIDSampleTestIds.documentSheet,
      onClose: onClose
    ) {
      UseSmileIDSampleCataloguePicker(
        catalogue: catalogue,
        loadingLabel: UseSmileIDSampleStrings.pickerDocumentLoading,
        failedLabel: UseSmileIDSampleStrings.pickerDocumentLoadFailed,
        query: $query,
        searchPlaceholder: UseSmileIDSampleStrings.pickerDocumentSearch,
        searchTestId: UseSmileIDSampleTestIds.documentSearch,
        label: \.name,
        emptyTestId: UseSmileIDSampleTestIds.documentEmpty,
        emptyLabel: UseSmileIDSampleStrings.pickerDocumentNoMatch(query: query),
        nothingToList: (UseSmileIDSampleStrings.pickerDocumentEmpty(country: country?.name ?? UseSmileIDSampleStrings.pickerThisCountry), UseSmileIDSampleStrings.pickerChooseAnotherCountry),
        onRetry: onRetry
      ) { document in
        UseSmileIDSampleOptionRow(
          label: document.name,
          selected: document.id == selected?.id,
          testId: UseSmileIDSampleTestIds.documentOption(document.id),
          onTap: { onSelect(document) }
        )
      }
    }
  }
}
