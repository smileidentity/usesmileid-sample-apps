import SwiftUI

/// The list's own UI state, in the app state: one tab is mounted, so a screen's own would die with it.
public struct UseSmileIDSampleVerificationsScreenState: Equatable {
  public var filter: UseSmileIDSampleJobFilter
  public private(set) var selectMode: Bool
  public private(set) var selected: Set<String>

  public init(
    filter: UseSmileIDSampleJobFilter = .all,
    selectMode: Bool = false,
    selected: Set<String> = []
  ) {
    self.filter = filter
    self.selectMode = selectMode
    self.selected = selected
  }

  /// Cleared on the way IN, so the bar still shows its count while it slides away.
  public mutating func changeSelectMode(_ on: Bool) {
    selectMode = on
    if on {
      selected = []
    }
  }

  public mutating func setSelection(_ id: String, _ checked: Bool) {
    if checked {
      selected.insert(id)
    } else {
      selected.remove(id)
    }
  }
}

/// Everything the list renders, so the screen owns no clock, store or selection of its own.
public struct UseSmileIDSampleVerificationsState: Equatable {
  /// Nil until the rows have loaded, so an empty state cannot be drawn over a list that is coming.
  public var jobs: [UseSmileIDSampleJob]?
  public var counts: [UseSmileIDSampleJobFilter: Int]
  public var filter: UseSmileIDSampleJobFilter
  public var selectMode: Bool
  public var selected: Set<String>
  /// Midnight, not the current instant: only the TODAY/YESTERDAY bucket reads the clock.
  public var today: Date
  /// Carries the locale and time zone the headers and row times are formatted in; a golden pins it.
  public var calendar: Calendar

  public init(
    jobs: [UseSmileIDSampleJob]?,
    counts: [UseSmileIDSampleJobFilter: Int] = [:],
    filter: UseSmileIDSampleJobFilter = .all,
    selectMode: Bool = false,
    selected: Set<String> = [],
    today: Date = useSmileIDSampleStartOfDay(Date()),
    calendar: Calendar = .current
  ) {
    self.jobs = jobs
    self.counts = counts
    self.filter = filter
    self.selectMode = selectMode
    self.selected = selected
    self.today = today
    self.calendar = calendar
  }
}

/// The verifications, grouped by day. Counts come from the whole list: a dropping count proves a removal.
public struct VerificationsScreen: View {
  private let state: UseSmileIDSampleVerificationsState
  private let onFilterChange: (UseSmileIDSampleJobFilter) -> Void
  private let onSelectModeChange: (Bool) -> Void
  private let onSelectionChange: (String, Bool) -> Void
  private let onJobTap: (UseSmileIDSampleJob) -> Void
  private let onRemove: (Set<String>) -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleVerificationsState,
    onFilterChange: @escaping (UseSmileIDSampleJobFilter) -> Void,
    onSelectModeChange: @escaping (Bool) -> Void,
    onSelectionChange: @escaping (String, Bool) -> Void,
    onJobTap: @escaping (UseSmileIDSampleJob) -> Void,
    onRemove: @escaping (Set<String>) -> Void
  ) {
    self.state = state
    self.onFilterChange = onFilterChange
    self.onSelectModeChange = onSelectModeChange
    self.onSelectionChange = onSelectionChange
    self.onJobTap = onJobTap
    self.onRemove = onRemove
  }

  public var body: some View {
    // Derived once per render, not per row: the index and the time labels are whole-list answers.
    let rows = Rows(state)
    return ScrollView {
      LazyVStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
        header
        chips
        emptyState(rows)
        ForEach(rows.days) { day in
          UseSmileIDSampleDateGroupHeader(relative: day.relative, absolute: day.absolute)
            .padding(.horizontal, SmileSpacing.spacingMd)
          ForEach(day.jobs, id: \.id) { job in
            row(job, in: rows)
          }
        }
      }
      .padding(.bottom, SmileSpacing.spacingXs)
    }
    .background(colors.background)
    // On the scroll view: on the stack inside it the id would override every child's.
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.verificationsScreen)
  }

  private var header: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleText("Verifications", style: UseSmileIDSampleTheme.type.textStyleHeadingPage)
        .foregroundColor(colors.textTitle)
        .frame(maxWidth: .infinity, alignment: .leading)
      Button(action: { onSelectModeChange(!state.selectMode) }) {
        UseSmileIDSampleText(
          state.selectMode ? "Cancel" : "Select",
          style: UseSmileIDSampleTheme.type.linkFont.with(weight: 700)
        )
        .foregroundColor(colors.primary)
        .lineLimit(1)
        .padding(.horizontal, SmileSpacing.spacingXs)
        .frame(minHeight: Self.target)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.selectToggle)
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingXs)
  }

  /// Scrolled, not wrapped, which is what iOS does with a filter row and stays honest at every content size.
  private var chips: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: SmileSpacing.spacingXs) {
        ForEach(UseSmileIDSampleJobFilter.allCases, id: \.self) { filter in
          UseSmileIDSampleFilterChip(
            label: filter.label,
            count: state.counts[filter] ?? 0,
            selected: filter == state.filter,
            testId: UseSmileIDSampleTestIds.filterChip(filter.id),
            countTestId: UseSmileIDSampleTestIds.filterCount(filter.id),
            onTap: { onFilterChange(filter) }
          )
        }
      }
      .padding(.horizontal, SmileSpacing.spacingMd)
    }
  }

  /// Two messages: "nothing yet" and "nothing matching this filter" are different things to be told.
  @ViewBuilder
  private func emptyState(_ rows: Rows) -> some View {
    if let jobs = state.jobs, rows.days.isEmpty {
      if jobs.isEmpty {
        UseSmileIDSampleEmptyState(
          text: "No verifications yet",
          supportingText: "Start a product above and the job lands here.",
          testId: UseSmileIDSampleTestIds.verificationsEmpty
        )
      } else {
        UseSmileIDSampleEmptyState(
          text: "Nothing \(state.filter.label.lowercased())",
          supportingText: "Other filters still have verifications.",
          testId: UseSmileIDSampleTestIds.verificationsEmpty
        )
      }
    }
  }

  private func row(_ job: UseSmileIDSampleJob, in rows: Rows) -> some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      // Beside the card, not inside it: the design narrows the card to make room.
      if state.selectMode {
        UseSmileIDSampleSelectionCheckbox(
          checked: Binding(
            get: { state.selected.contains(job.id) },
            set: { onSelectionChange(job.id, $0) }
          ),
          testId: UseSmileIDSampleTestIds.selectionCheckbox(rows.index[job.id] ?? 0)
        )
      }
      card(job, in: rows)
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
  }

  @ViewBuilder
  private func card(_ job: UseSmileIDSampleJob, in rows: Rows) -> some View {
    // Swipe is off in select mode, where the gesture would fight the checkbox.
    if state.selectMode {
      jobRow(job, in: rows)
    } else {
      UseSmileIDSampleSwipeAction(onRemove: { onRemove([job.id]) }) {
        jobRow(job, in: rows)
      }
    }
  }

  private func jobRow(_ job: UseSmileIDSampleJob, in rows: Rows) -> some View {
    UseSmileIDSampleJobRow(
      product: job.product,
      jobId: job.shortId,
      time: rows.times[job.id] ?? "",
      status: job.status,
      testId: UseSmileIDSampleTestIds.jobRow(rows.index[job.id] ?? 0),
      statusTestId: UseSmileIDSampleTestIds.jobRowStatus,
      onTap: state.selectMode ? nil : { onJobTap(job) }
    )
  }

  private static let target: CGFloat = 44

  /// The day groups, each row's index in the whole visible list rather than in its group, and its time.
  private struct Rows {
    let days: [UseSmileIDSampleJobDay]
    let index: [String: Int]
    let times: [String: String]

    init(_ state: UseSmileIDSampleVerificationsState) {
      let visible = state.jobs?.filter(state.filter.matches) ?? []
      days = visible.groupByDay(state.today, calendar: state.calendar)
      // First value wins rather than trapping: the store's ids are unique, and this is a public screen.
      index = Dictionary(
        days.flatMap(\.jobs).enumerated().map { ($0.element.id, $0.offset) },
        uniquingKeysWith: { first, _ in first }
      )
      times = visible.timeLabels(calendar: state.calendar)
    }
  }
}
