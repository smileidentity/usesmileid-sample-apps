import SwiftUI

/// The ID-type picker. Its list depends on the country, which is why the trigger needs one first.
public struct IdTypePickerSheet: View {
  private let country: UseSmileIDSampleCountry?
  private let selected: UseSmileIDSampleIdType?
  @Binding private var query: String
  private let onSelect: (UseSmileIDSampleIdType) -> Void
  private let onClose: () -> Void

  public init(
    country: UseSmileIDSampleCountry?,
    selected: UseSmileIDSampleIdType?,
    query: Binding<String>,
    onSelect: @escaping (UseSmileIDSampleIdType) -> Void,
    onClose: @escaping () -> Void
  ) {
    self.country = country
    self.selected = selected
    _query = query
    self.onSelect = onSelect
    self.onClose = onClose
  }

  public var body: some View {
    UseSmileIDSampleFullHeightBottomSheet(
      title: "ID type",
      testId: UseSmileIDSampleTestIds.idTypeSheet,
      onClose: onClose
    ) {
      UseSmileIDSampleSearchField(
        query: $query,
        placeholder: "Search ID type",
        testId: UseSmileIDSampleTestIds.idTypeSearch
      )
      UseSmileIDSamplePickerList(
        isEmpty: matches.isEmpty,
        emptyLabel: emptyLabel,
        emptyTestId: UseSmileIDSampleTestIds.idTypeEmpty
      ) {
        ForEach(matches, id: \.self) { idType in
          UseSmileIDSampleOptionRow(
            label: idType.label,
            selected: idType == selected,
            testId: UseSmileIDSampleTestIds.idTypeOption(idType.id),
            onTap: { onSelect(idType) }
          )
        }
      }
    }
  }

  private var matches: [UseSmileIDSampleIdType] {
    UseSmileIDSampleIdType.of(country, matching: query)
  }

  private var emptyLabel: String {
    query.isBlank ? "No ID type for this country" : "No ID type matches \u{201C}\(query)\u{201D}"
  }
}
