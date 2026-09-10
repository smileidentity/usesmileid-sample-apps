import SwiftUI

/// The loupe itself: recorded traffic, what it adds up to, and what is being recorded.
struct LoupeRootView: View {
  @Bindable var store: LoupeStore
  let loupe: Loupe
  let onClose: () -> Void

  var body: some View {
    NavigationStack {
      TabView {
        traffic
          .tabItem { Label("Traffic", systemImage: "arrow.left.arrow.right") }
        LoupeStatisticsView(statistics: LoupeStatistics(records: store.records))
          .tabItem { Label("Statistics", systemImage: "chart.bar") }
        LoupeSettingsView(loupe: loupe, recordCount: store.records.count) { store.clear() }
          .tabItem { Label("Settings", systemImage: "gearshape") }
      }
      .navigationDestination(for: LoupeRecord.self) { record in
        LoupeRecordDetailView(record: record)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close", action: onClose)
        }
        ToolbarItem(placement: .primaryAction) {
          ShareLink("Export", item: LoupeExport.text(for: store.records))
            .disabled(store.records.isEmpty)
        }
      }
    }
  }

  @ViewBuilder private var traffic: some View {
    let records = store.visibleRecords
    VStack(spacing: 0) {
      LoupeKindFilter(store: store)
      if records.isEmpty {
        emptyState
      } else {
        List(records) { record in
          NavigationLink(value: record) {
            LoupeRecordRow(record: record)
          }
        }
        .listStyle(.plain)
      }
    }
    .navigationTitle("Traffic")
    .navigationBarTitleDisplayMode(.inline)
    .searchable(text: $store.searchText, prompt: "Filter by URL")
  }

  @ViewBuilder private var emptyState: some View {
    if store.records.isEmpty {
      ContentUnavailableView(
        "No requests yet",
        systemImage: "antenna.radiowaves.left.and.right",
        description: Text("Traffic appears here as the app makes it.")
      )
    } else {
      ContentUnavailableView.search
    }
  }
}

/// The body-kind chips, above the list so a filter you set stays visible.
private struct LoupeKindFilter: View {
  let store: LoupeStore

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(LoupeBodyKind.allCases, id: \.self) { kind in
          let isOn = store.visibleKinds.contains(kind)
          Button { store.toggle(kind) } label: {
            Text(kind.rawValue)
              .font(.caption)
              .padding(.horizontal, 10)
              .padding(.vertical, 5)
              .background(isOn ? Color.accentColor : Color(.secondarySystemBackground))
              .foregroundStyle(isOn ? Color.white : Color.primary)
              .clipShape(Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal)
    }
    .padding(.vertical, 8)
  }
}
