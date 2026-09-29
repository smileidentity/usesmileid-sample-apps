import SwiftUI

/// The ID-type picker. Its list depends on the country, which is why the trigger needs one first.
public struct IdTypePickerSheet: View {
  private let country: UseSmileIDSampleCountry?
  private let catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType>
  private let selected: UseSmileIDSampleKycIdType?
  @Binding private var query: String
  private let onSelect: (UseSmileIDSampleKycIdType) -> Void
  private let onRetry: () -> Void
  private let onClose: () -> Void

  public init(
    country: UseSmileIDSampleCountry?,
    catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType>,
    selected: UseSmileIDSampleKycIdType?,
    query: Binding<String>,
    onSelect: @escaping (UseSmileIDSampleKycIdType) -> Void,
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
      title: "ID type",
      testId: UseSmileIDSampleTestIds.idTypeSheet,
      onClose: onClose
    ) {
      UseSmileIDSampleCataloguePicker(
        catalogue: catalogue,
        what: "ID types",
        query: $query,
        searchPlaceholder: "Search ID type",
        searchTestId: UseSmileIDSampleTestIds.idTypeSearch,
        label: \.label,
        emptyTestId: UseSmileIDSampleTestIds.idTypeEmpty,
        emptyLabel: "No ID type matches \u{201C}\(query)\u{201D}",
        nothingToList: ("No ID types for \(country?.name ?? "this country")", "Choose another country"),
        onRetry: onRetry
      ) { idType in
        UseSmileIDSampleOptionRow(
          label: idType.label,
          selected: idType.id == selected?.id,
          testId: UseSmileIDSampleTestIds.idTypeOption(idType.id),
          onTap: { onSelect(idType) }
        )
      }
    }
  }
}
