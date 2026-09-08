import SwiftUI

/// A nil job is a real state: a deep link can name one this build never had.
public struct UseSmileIDSampleVerificationDetailsState: Equatable {
  public var jobId: String
  public var job: UseSmileIDSampleJob?
  /// Rendered whether or not the job resolved: a run that failed before submission has nothing else.
  public var result: UseSmileIDSampleResult
  /// Computed by the host: `sample-ui` reads no build configuration and no launch argument.
  public var showProbes: Bool

  public init(
    jobId: String,
    job: UseSmileIDSampleJob? = nil,
    result: UseSmileIDSampleResult = UseSmileIDSampleFlowResult().snapshot,
    showProbes: Bool = true
  ) {
    self.jobId = jobId
    self.job = job
    self.result = result
    self.showProbes = showProbes
  }
}

/// One verification, and where the flow lands after submission.
public struct VerificationDetailsScreen: View {
  private let state: UseSmileIDSampleVerificationDetailsState
  /// The card's toggle, lifted to the caller so a tab switch cannot re-expand it.
  @Binding private var resultExpanded: Bool
  private let onBack: () -> Void
  private let onDelete: () -> Void
  private let onCopy: (String, String) -> Void
  private let onRefresh: () async -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleVerificationDetailsState,
    resultExpanded: Binding<Bool>,
    onBack: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onCopy: @escaping (String, String) -> Void,
    // Always wired, never conditionally hidden: a refresh that cannot succeed says why instead.
    onRefresh: @escaping () async -> Void = {}
  ) {
    self.state = state
    _resultExpanded = resultExpanded
    self.onBack = onBack
    self.onDelete = onDelete
    self.onCopy = onCopy
    self.onRefresh = onRefresh
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: "Verification details", onBack: onBack) {
        deleteAction
      }
      ScrollView {
        VStack(spacing: SmileSpacing.spacingSm) {
          if let job = state.job {
            heading(job)
            details(job)
          } else {
            UseSmileIDSampleEmptyState(
              text: "No verification here",
              supportingText: "Nothing stored for jobId = \(state.jobId)",
              testId: UseSmileIDSampleTestIds.detailsEmpty
            )
          }
          if state.showProbes {
            UseSmileIDSampleResultCard(result: state.result, expanded: $resultExpanded)
              .padding(.horizontal, SmileSpacing.spacingMd)
          }
        }
        .padding(.vertical, SmileSpacing.spacingXs)
      }
      // The refresh container carries that id; the screen's own goes on the stack, which needs `.contain`.
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.detailsRefresh)
      // SwiftUI owns the indicator while the action runs. The gesture needs iOS 16; see §15.
      .refreshable { await onRefresh() }
    }
    .background(colors.background)
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.verificationDetailsScreen)
  }

  /// Absent with no row: there is nothing to hide.
  @ViewBuilder
  private var deleteAction: some View {
    if state.job != nil {
      UseSmileIDSampleTopAppBarButton(
        label: "Hide verification from the app list",
        emphasis: .destructive,
        testId: UseSmileIDSampleTestIds.detailsDelete,
        action: onDelete
      ) { tint in
        UseSmileIDSampleIcon(SmileIcons.trash, tint: tint, size: SmileSpacing.sizeIconMd)
      }
    }
  }

  private func heading(_ job: UseSmileIDSampleJob) -> some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      UseSmileIDSampleText(job.product.label, style: UseSmileIDSampleTheme.type.textStyleTitle)
        .foregroundColor(colors.textTitle)
        .frame(maxWidth: .infinity, alignment: .leading)
      UseSmileIDSampleStatusBadge(status: job.status, testId: UseSmileIDSampleTestIds.statusBadge)
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingXxs)
  }

  private func details(_ job: UseSmileIDSampleJob) -> some View {
    UseSmileIDSampleSectionSurface(label: "DETAILS") {
      row("createdAt", "Created_at", job.createdAtLabel)
      row("jobId", "Job_id", job.shortId) { onCopy("Job ID", job.id) }
      row("message", "Message", job.message)
      // Coloured by the HTTP outcome, not the verdict: a blocked job still shows a green 200.
      row("status", "Status", httpStatusLabel(job), valueColor: httpStatusColor(job))
      row("userId", "User_id", job.shortUserId) { onCopy("User ID", job.userId) }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
  }

  private func row(
    _ field: String,
    _ label: String,
    _ value: String,
    valueColor: Color? = nil,
    onCopy: (() -> Void)? = nil
  ) -> some View {
    UseSmileIDSampleDataFieldRow(
      label: label,
      value: value,
      valueColor: valueColor,
      testId: UseSmileIDSampleTestIds.detailField(field),
      copyTestId: UseSmileIDSampleTestIds.detailCopy(field),
      onCopy: onCopy
    )
  }

  /// The design's row shows "200 OK"; only the codes the app actually writes get a reason phrase.
  private func httpStatusLabel(_ job: UseSmileIDSampleJob) -> String {
    guard let code = job.httpStatus else { return "" }
    switch code {
    case 200: return "200 OK"
    case 202: return "202 Accepted"
    default: return String(code)
    }
  }

  /// Green while the call succeeded, red once it did not; no status is neither.
  private func httpStatusColor(_ job: UseSmileIDSampleJob) -> Color? {
    guard let code = job.httpStatus else { return nil }
    return (200..<300).contains(code) ? colors.badge.successText : colors.badge.errorText
  }
}
