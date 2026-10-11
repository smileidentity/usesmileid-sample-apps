import SwiftUI

/// SmartSelfie Authentication's user ID: typed, or picked from earlier runs that enrolled one. Never made up, because the SDK authenticates only an enrolled user.
public struct AuthUserIdScreen: View {
  private let userId: String
  private let previousUsers: [UseSmileIDSampleJob]
  private let onUserIdChange: (String) -> Void
  private let onRegister: () -> Void
  private let onBack: () -> Void
  private let onContinue: () -> Void

  @Environment(\.useSmileIDSampleColors) private var colors

  /// `previousUsers` is the newest run per enrolled user, newest first.
  public init(
    userId: String,
    previousUsers: [UseSmileIDSampleJob],
    onUserIdChange: @escaping (String) -> Void,
    onRegister: @escaping () -> Void,
    onBack: @escaping () -> Void,
    onContinue: @escaping () -> Void
  ) {
    self.userId = userId
    self.previousUsers = previousUsers
    self.onUserIdChange = onUserIdChange
    self.onRegister = onRegister
    self.onBack = onBack
    self.onContinue = onContinue
  }

  private var chosen: String {
    userId.trimmingCharacters(in: .whitespaces)
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: UseSmileIDSampleProduct.smartSelfieAuth.label, onBack: onBack)
      ScrollView {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
          UseSmileIDSampleSectionLabel(UseSmileIDSampleStrings.authUserIdSection)
          UseSmileIDSampleTextInput(
            value: Binding(get: { userId }, set: onUserIdChange),
            placeholder: UseSmileIDSampleStrings.authUserIdPlaceholder,
            keyboardType: .asciiCapable,
            testId: UseSmileIDSampleTestIds.authUserIdInput
          )
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          caption(UseSmileIDSampleStrings.authUserIdHint)
          orDivider
          if previousUsers.isEmpty {
            listSection(UseSmileIDSampleStrings.authUserIdRun, hint: UseSmileIDSampleStrings.authUserIdRunBody)
            AuthUserIdEnrollmentCard(onTap: onRegister)
          } else {
            listSection(UseSmileIDSampleStrings.authUserIdPrevious, hint: UseSmileIDSampleStrings.authUserIdPreviousHint)
            let times = previousUsers.timeLabels()
            VStack(spacing: SmileSpacing.spacingXs) {
              ForEach(Array(previousUsers.enumerated()), id: \.element.userId) { index, job in
                AuthUserIdPreviousCard(
                  job: job,
                  time: times[job.id] ?? "",
                  latest: index == 0,
                  selected: job.userId == chosen,
                  testId: UseSmileIDSampleTestIds.authUserIdOption(index),
                  onTap: { onUserIdChange(job.userId) }
                )
              }
            }
          }
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
        .padding(.bottom, SmileSpacing.spacingSm)
      }
      UseSmileIDSampleButton(
        text: UseSmileIDSampleStrings.commonContinue,
        enabled: !chosen.isEmpty,
        testId: UseSmileIDSampleTestIds.authUserIdContinue,
        action: onContinue
      )
      .padding(SmileSpacing.spacingMd)
    }
    .background(colors.background)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.authUserIdScreen)
  }

  private var orDivider: some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      hairline
      UseSmileIDSampleText(
        UseSmileIDSampleStrings.authUserIdOr,
        style: UseSmileIDSampleTheme.type.textStyleOverline.with(size: smileLabelSize, tracking: smileLabelTracking)
      )
      .foregroundColor(colors.textMuted)
      hairline
    }
    .padding(.vertical, SmileSpacing.spacingXs)
  }

  private var hairline: some View {
    Rectangle().fill(colors.cardStroke).frame(height: smileCardStrokeWidth)
  }

  private func listSection(_ label: String, hint: String) -> some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
      UseSmileIDSampleSectionLabel(label)
      caption(hint)
    }
  }

  private func caption(_ text: String) -> some View {
    UseSmileIDSampleText(text, style: UseSmileIDSampleTheme.type.textStyleCaption)
      .foregroundColor(colors.textMuted)
      .fixedSize(horizontal: false, vertical: true)
  }
}

/// An earlier user, laid out like a verifications row.
private struct AuthUserIdPreviousCard: View {
  let job: UseSmileIDSampleJob
  let time: String
  let latest: Bool
  let selected: Bool
  let testId: String
  let onTap: () -> Void

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @ScaledMetric(relativeTo: .body) private var tileSize: CGFloat = 36
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: SmileSpacing.spacingSm) {
        UseSmileIDSampleProductTile(job.product, side: tileSize, iconSize: 18)
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
          UseSmileIDSampleText(job.product.label, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
            .foregroundColor(colors.card.title)
          UseSmileIDSampleText("\(job.middleUserId) · \(time)", style: UseSmileIDSampleTheme.type.textStyleCaption)
            .foregroundColor(colors.textMuted)
          if latest, stacks {
            latestPill
          }
        }
        .lineLimit(stacks ? nil : 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        if latest, !stacks {
          latestPill
        }
      }
      .padding(SmileSpacing.spacingSm)
      .frame(minHeight: minHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .fill(colors.card.background)
      )
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .strokeBorder(
            selected ? colors.primary : colors.cardStroke,
            lineWidth: selected ? SmileSpacing.borderWidthThin : smileCardStrokeWidth
          )
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? .isSelected : [])
    .useSmileIDSampleTestId(testId)
  }

  private var stacks: Bool {
    sizeCategory.isAccessibilityCategory
  }

  private var latestPill: some View {
    UseSmileIDSamplePill(
      label: UseSmileIDSampleStrings.authUserIdLatest,
      background: colors.badge.infoBackground,
      foreground: colors.badge.infoText
    )
  }
}

/// Starts SmartSelfie Enrollment.
private struct AuthUserIdEnrollmentCard: View {
  let onTap: () -> Void

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space64
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: SmileSpacing.spacingSm) {
        UseSmileIDSampleProductTile(.smartSelfieEnrollment)
        UseSmileIDSampleText(UseSmileIDSampleProduct.smartSelfieEnrollment.label, style: UseSmileIDSampleTheme.type.textStyleBodyStrong)
          .foregroundColor(colors.card.title)
          .frame(maxWidth: .infinity, alignment: .leading)
        UseSmileIDSampleSettingRowChevron()
      }
      .padding(SmileSpacing.spacingSm)
      .frame(minHeight: minHeight)
      .background(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .fill(colors.card.background)
      )
      .overlay(
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
          .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.authUserIdRegister)
  }
}
