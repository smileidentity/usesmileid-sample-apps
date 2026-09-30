import SwiftUI

/// The country picker, presented as a layer over the form that owns it rather than a destination.
public struct CountryPickerSheet: View {
  private let catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleCountry>
  private let selected: UseSmileIDSampleCountry?
  @Binding private var query: String
  private let onSelect: (UseSmileIDSampleCountry) -> Void
  private let onRetry: () -> Void
  private let onClose: () -> Void

  public init(
    catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleCountry>,
    selected: UseSmileIDSampleCountry?,
    query: Binding<String>,
    onSelect: @escaping (UseSmileIDSampleCountry) -> Void,
    onRetry: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    self.catalogue = catalogue
    self.selected = selected
    _query = query
    self.onSelect = onSelect
    self.onRetry = onRetry
    self.onClose = onClose
  }

  public var body: some View {
    UseSmileIDSampleFullHeightBottomSheet(
      title: "Country",
      testId: UseSmileIDSampleTestIds.countrySheet,
      onClose: onClose
    ) {
      UseSmileIDSampleCataloguePicker(
        catalogue: catalogue,
        what: "countries",
        query: $query,
        searchPlaceholder: "Search country",
        searchTestId: UseSmileIDSampleTestIds.countrySearch,
        label: \.name,
        emptyTestId: UseSmileIDSampleTestIds.countryEmpty,
        emptyLabel: "No country matches \u{201C}\(query)\u{201D}",
        nothingToList: ("No countries for this product", "Try another product"),
        leadingCircle: true,
        onRetry: onRetry
      ) { country in
        UseSmileIDSampleOptionRow(
          label: country.name,
          leadingText: country.flag,
          selected: country.code == selected?.code,
          testId: UseSmileIDSampleTestIds.countryOption(country.code),
          onTap: { onSelect(country) }
        )
      }
    }
  }
}

/// One picker's body: skeleton rows while loading, an error with Retry, an empty state without one, and a search.
struct UseSmileIDSampleCataloguePicker<Item: Hashable & Sendable, Row: View>: View {
  let catalogue: UseSmileIDSampleCatalogue<Item>
  let what: String
  @Binding var query: String
  let searchPlaceholder: String
  let searchTestId: String
  let label: (Item) -> String
  let emptyTestId: String
  let emptyLabel: String
  let nothingToList: (String, String)
  var leadingCircle = false
  let onRetry: () -> Void
  @ViewBuilder let row: (Item) -> Row

  @StateObject private var gate = UseSmileIDSampleSkeletonGate()
  @Environment(\.useSmileIDSampleSkeletonDelay) private var skeletonDelay

  private var showsSkeleton: Bool {
    gate.visible || (skeletonDelay == 0 && catalogue.isLoading)
  }

  var body: some View {
    Group {
      UseSmileIDSampleSearchField(
        query: $query,
        placeholder: searchPlaceholder,
        testId: searchTestId,
        enabled: isReady && !showsSkeleton
      )
      content
    }
    .onAppear { gate.loading(catalogue.isLoading) }
    .onChange(of: catalogue.isLoading) { gate.loading($0) }
  }

  @ViewBuilder
  private var content: some View {
    if showsSkeleton {
      UseSmileIDSampleSkeletonRows(
        announcement: "Loading \(what)",
        leadingCircle: leadingCircle,
        testId: UseSmileIDSampleTestIds.catalogueLoading
      )
    } else {
      switch catalogue {
      // The first 300 ms draw nothing, so a fast answer never flashes a skeleton.
      case .loading:
        EmptyView()
      case .failed(_, let advice):
        UseSmileIDSampleEmptyState(
          text: "Couldn't load \(what)",
          supportingText: advice,
          testId: UseSmileIDSampleTestIds.catalogueError,
          onRetry: onRetry,
          retryTestId: UseSmileIDSampleTestIds.catalogueRetry
        )
      case .ready(let items):
        let matches = items.filter { label($0).matches(query) }
        if matches.isEmpty {
          UseSmileIDSampleEmptyState(text: emptyLabel, testId: emptyTestId)
        } else {
          VStack(spacing: SmileSpacing.spacingXxs) {
            ForEach(matches, id: \.self) { row($0) }
          }
        }
      case .empty:
        UseSmileIDSampleEmptyState(text: nothingToList.0, supportingText: nothingToList.1, testId: emptyTestId)
      }
    }
  }

  private var isReady: Bool {
    if case .ready = catalogue {
      return true
    }
    return false
  }
}
