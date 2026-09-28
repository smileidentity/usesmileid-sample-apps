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
      title: "Document",
      testId: UseSmileIDSampleTestIds.documentSheet,
      onClose: onClose
    ) {
      UseSmileIDSampleCataloguePicker(
        catalogue: catalogue,
        what: "documents",
        query: $query,
        searchPlaceholder: "Search document",
        searchTestId: UseSmileIDSampleTestIds.documentSearch,
        label: \.name,
        emptyTestId: UseSmileIDSampleTestIds.documentEmpty,
        emptyLabel: "No document matches \u{201C}\(query)\u{201D}",
        nothingToList: ("No documents for \(country?.name ?? "this country")", "Choose another country"),
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
