@testable import SampleUI
import SwiftUI
import XCTest

final class UseSmileIDSampleListChromeGoldenTest: UseSmileIDSampleGoldenTest {
  func testJobRows() {
    goldens("job_rows") { JobRows() }
  }

  func testJobRowsSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { JobRows() }
  }

  func testFilterChips() {
    goldens("filter_chips") { FilterChips() }
  }

  func testFilterChipsSurviveMaxDynamicType() {
    assertSurvivesMaxDynamicType { FilterChips() }
  }

  func testDateGroupHeader() {
    goldens("date_group_header") { DateGroupHeaders() }
  }

  func testSelectionBar() {
    goldens("selection_bar") { SelectionBars() }
  }

  func testSelectionBarSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { SelectionBars() }
  }

  func testSelectionCheckboxes() {
    goldens("selection_checkboxes") { SelectionCheckboxes() }
  }

  func testBottomSheet() {
    goldens("bottom_sheet") { SheetContent() }
  }
}

private struct JobRows: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleJobRow(
        product: .smartSelfieAuth,
        jobId: "job-8f21c4de",
        time: "14:03",
        status: .clear
      )
      UseSmileIDSampleJobRow(
        product: .enhancedDocumentVerification,
        jobId: "job-1a92bb07",
        time: "13:48",
        status: .processing
      )
      // Enhanced KYC has no icon of its own, so it renders the generic product mark.
      UseSmileIDSampleJobRow(
        product: .enhancedKyc,
        jobId: "job-77c0e451",
        time: "11:20",
        status: .blocked
      )
    }
  }
}

private struct FilterChips: View {
  var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleFilterChip(label: "All", count: 12, selected: true, onTap: {})
      UseSmileIDSampleFilterChip(label: "Clear", count: 7, selected: false, onTap: {})
      UseSmileIDSampleFilterChip(label: "Blocked", count: 2, selected: false, onTap: {})
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct DateGroupHeaders: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      UseSmileIDSampleDateGroupHeader(relative: "Today", absolute: "28 Aug 2026")
      UseSmileIDSampleDateGroupHeader(relative: "Yesterday", absolute: "27 Aug 2026")
    }
  }
}

private struct SelectionBars: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleSelectionBar(selectedCount: 0, onRemove: {})
      UseSmileIDSampleSelectionBar(selectedCount: 3, onRemove: {})
    }
  }
}

private struct SelectionCheckboxes: View {
  var body: some View {
    HStack(spacing: SmileSpacing.spacingLg) {
      UseSmileIDSampleSelectionCheckbox(checked: .constant(true))
      UseSmileIDSampleSelectionCheckbox(checked: .constant(false))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SheetContent: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      UseSmileIDSampleSheetHeader(title: "Select country", onClose: {})
      UseSmileIDSampleBottomSheet(title: "Switch profile") {
        UseSmileIDSampleOptionRow(label: "Nigeria", leadingText: "🇳🇬", selected: true, onTap: {})
        UseSmileIDSampleOptionRow(label: "Kenya", leadingText: "🇰🇪", selected: false, onTap: {})
      }
      .frame(height: 200)
    }
  }
}
