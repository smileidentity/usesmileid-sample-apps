import SwiftUI

/// What the details screen draws. A nil job is a real state: a deep link can name one this build
/// never had, and the id asked for is the whole diagnostic.
public struct UseSmileIDSampleVerificationDetailsState: Equatable {
  public var jobId: String
  public var job: UseSmileIDSampleJob?

  public init(jobId: String, job: UseSmileIDSampleJob? = nil) {
    self.jobId = jobId
    self.job = job
  }
}

/// One verification, and where the flow lands after submission.
public struct VerificationDetailsScreen: View {
  private let state: UseSmileIDSampleVerificationDetailsState
  private let onBack: () -> Void
  private let onDelete: () -> Void
  private let onCopy: (String, String) -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    state: UseSmileIDSampleVerificationDetailsState,
    onBack: @escaping () -> Void,
    onDelete: @escaping () -> Void,
    onCopy: @escaping (String, String) -> Void
  ) {
    self.state = state
    self.onBack = onBack
    self.onDelete = onDelete
    self.onCopy = onCopy
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
        }
        .padding(.vertical, SmileSpacing.spacingXs)
      }
      // On the scroll view, as the other screens' are: on the stack inside it, the id would
      // override every child's.
      .useSmileIDSampleTestId(UseSmileIDSampleTestIds.verificationDetailsScreen)
    }
    .background(colors.background)
  }

  /// Absent with no row: there is nothing to hide, and the copy would name a job that is not there.
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

  /// Green while the call succeeded, red once it did not. No status is neither: colouring it red
  /// would invent a failure.
  private func httpStatusColor(_ job: UseSmileIDSampleJob) -> Color? {
    guard let code = job.httpStatus else { return nil }
    return (200..<300).contains(code) ? colors.badge.successText : colors.badge.errorText
  }
}
