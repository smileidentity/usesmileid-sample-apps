import SwiftUI

/// The country picker, presented as a layer over the form that owns it rather than a destination.
public struct CountryPickerSheet: View {
  private let selected: UseSmileIDSampleCountry?
  @Binding private var query: String
  private let onSelect: (UseSmileIDSampleCountry) -> Void

  public init(
    selected: UseSmileIDSampleCountry?,
    query: Binding<String>,
    onSelect: @escaping (UseSmileIDSampleCountry) -> Void
  ) {
    self.selected = selected
    _query = query
    self.onSelect = onSelect
  }

  public var body: some View {
    UseSmileIDSampleBottomSheet(title: "Country", testId: UseSmileIDSampleTestIds.countrySheet) {
      UseSmileIDSampleSearchField(
        query: $query,
        placeholder: "Search country",
        testId: UseSmileIDSampleTestIds.countrySearch
      )
      UseSmileIDSamplePickerList(
        isEmpty: matches.isEmpty,
        emptyLabel: "No country matches \u{201C}\(query)\u{201D}",
        emptyTestId: UseSmileIDSampleTestIds.countryEmpty
      ) {
        ForEach(matches, id: \.self) { country in
          UseSmileIDSampleOptionRow(
            label: country.label,
            leadingText: country.flag,
            selected: country == selected,
            testId: UseSmileIDSampleTestIds.countryOption(country.code),
            onTap: { onSelect(country) }
          )
        }
      }
    }
  }

  private var matches: [UseSmileIDSampleCountry] {
    UseSmileIDSampleCountry.matching(query)
  }
}

/// An empty result is a state a search must have, or a typo looks like a broken sheet. Internal and
/// beside its first caller, as the Compose twin is: the two picker sheets are its only consumers.
struct UseSmileIDSamplePickerList<Content: View>: View {
  private let isEmpty: Bool
  private let emptyLabel: String
  private let emptyTestId: String
  private let content: Content

  init(
    isEmpty: Bool,
    emptyLabel: String,
    emptyTestId: String,
    @ViewBuilder content: () -> Content
  ) {
    self.isEmpty = isEmpty
    self.emptyLabel = emptyLabel
    self.emptyTestId = emptyTestId
    self.content = content()
  }

  var body: some View {
    if isEmpty {
      UseSmileIDSampleEmptyState(text: emptyLabel, testId: emptyTestId)
    } else {
      VStack(spacing: SmileSpacing.spacingXxs) { content }
    }
  }
}
