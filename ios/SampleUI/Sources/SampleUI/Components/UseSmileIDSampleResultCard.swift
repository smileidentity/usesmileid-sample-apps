import SwiftUI

/// Every `spec/result-card.schema.json` field under its own id, expanded by default since a collapsed field leaves the tree; `expanded` is the caller's.
public struct UseSmileIDSampleResultCard: View {
  private let result: UseSmileIDSampleResult
  @Binding private var expanded: Bool

  @ScaledMetric(relativeTo: .body) private var headerHeight: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(result: UseSmileIDSampleResult, expanded: Binding<Bool>) {
    self.result = result
    _expanded = expanded
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button {
        expanded.toggle()
      } label: {
        HStack(spacing: SmileSpacing.spacingXs) {
          UseSmileIDSampleText("SDK RESULT", style: UseSmileIDSampleTheme.type.textStyleOverline)
            .foregroundColor(colors.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
          UseSmileIDSampleText(expanded ? "Hide" : "Show", style: UseSmileIDSampleTheme.type.textStyleCaption)
            .foregroundColor(colors.textLink)
        }
        .padding(.horizontal, SmileSpacing.spacingMd)
        .frame(minHeight: headerHeight)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(expanded ? "Collapse SDK result" : "Expand SDK result")
      if expanded {
        UseSmileIDSampleResultField("Scenario", result.activeScenario.id, UseSmileIDSampleTestIds.resultActiveScenario)
        UseSmileIDSampleResultField("Theme", result.activeTheme.id, UseSmileIDSampleTestIds.resultActiveTheme)
        UseSmileIDSampleResultField("Route", result.route.id, UseSmileIDSampleTestIds.resultRoute)
        UseSmileIDSampleResultField("Environment", result.environment.id, UseSmileIDSampleTestIds.resultEnvironment)
        UseSmileIDSampleResultField("Job id", result.jobId, UseSmileIDSampleTestIds.resultJobId)
        UseSmileIDSampleResultField("User id", result.userId, UseSmileIDSampleTestIds.resultUserId)
        UseSmileIDSampleResultField("Job status", result.jobStatus.id, UseSmileIDSampleTestIds.resultJobStatus)
        UseSmileIDSampleResultField(
          "Result callbacks",
          String(result.resultCallbackCount),
          UseSmileIDSampleTestIds.resultResultCount
        )
        UseSmileIDSampleResultField(
          "Refresh callbacks",
          String(result.refreshCallbackCount),
          UseSmileIDSampleTestIds.resultRefreshCount
        )
        UseSmileIDSampleResultField("Last error", result.lastError, UseSmileIDSampleTestIds.resultLastError)
        UseSmileIDSampleResultField("SDK version", result.sdkVersion, UseSmileIDSampleTestIds.resultSdkVersion)
      }
    }
    .padding(.vertical, SmileSpacing.spacingSm)
    .frame(maxWidth: .infinity)
    // Its ideal height, not a share of what is left, or the values truncate at large type.
    .fixedSize(horizontal: false, vertical: true)
    .background(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .fill(colors.surfaceAlt)
    )
    // A container that contains, or the card's id replaces every field's and a flow can read none.
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.resultCard)
  }
}

/// The compact form on products while a run is in flight: three fields, under the same ids as the card.
public struct UseSmileIDSampleResultLine: View {
  private let result: UseSmileIDSampleResult

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space40
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(result: UseSmileIDSampleResult) {
    self.result = result
  }

  public var body: some View {
    // Stacks once type grows: four values beside each other break the narrow ones mid-word.
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
          heading
          status
          scenario
          route
        }
      } else {
        HStack(spacing: SmileSpacing.spacingXs) {
          heading
          status.frame(maxWidth: .infinity, alignment: .leading)
          scenario
          route
        }
      }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingXs)
    .frame(minHeight: minHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.card, style: .continuous)
        .fill(colors.surfaceAlt)
    )
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.resultCard)
  }

  private var heading: some View {
    UseSmileIDSampleText("SDK", style: UseSmileIDSampleTheme.type.textStyleOverline)
      .foregroundColor(colors.textMuted)
  }

  private var status: some View {
    UseSmileIDSampleResultValue(result.jobStatus.id, UseSmileIDSampleTestIds.resultJobStatus)
  }

  private var scenario: some View {
    UseSmileIDSampleResultValue(result.activeScenario.id, UseSmileIDSampleTestIds.resultActiveScenario)
  }

  private var route: some View {
    UseSmileIDSampleResultValue(result.route.id, UseSmileIDSampleTestIds.resultRoute)
  }
}

/// One label and its value; a nil value still renders, since a missing id and an empty one are different failures.
private struct UseSmileIDSampleResultField: View {
  private let label: String
  private let value: String?
  private let testId: String

  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  init(_ label: String, _ value: String?, _ testId: String) {
    self.label = label
    self.value = value
    self.testId = testId
  }

  var body: some View {
    // Stacks once type grows; SwiftUI has no FlowRow on this floor, so the switch is explicit.
    Group {
      if sizeCategory.isAccessibilityCategory {
        VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
          labelText
          valueText.frame(maxWidth: .infinity, alignment: .leading)
        }
      } else {
        HStack(alignment: .firstTextBaseline, spacing: SmileSpacing.spacingXs) {
          labelText.layoutPriority(1)
          valueText
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
      }
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingXxs)
  }

  private var labelText: some View {
    UseSmileIDSampleText(label, style: UseSmileIDSampleTheme.type.textStyleCaption)
      .foregroundColor(colors.textMuted)
  }

  private var valueText: some View {
    UseSmileIDSampleResultValue(value, testId)
  }
}

private struct UseSmileIDSampleResultValue: View {
  private let value: String?
  private let testId: String

  @Environment(\.useSmileIDSampleColors) private var colors

  init(_ value: String?, _ testId: String) {
    self.value = value
    self.testId = testId
  }

  var body: some View {
    UseSmileIDSampleText(value ?? Self.nullValue, style: UseSmileIDSampleTheme.type.textStyleCaption)
      .foregroundColor(colors.textBody)
      .useSmileIDSampleTestId(testId)
  }

  /// Stable: flows assert on it to prove a value was absent.
  private static let nullValue = "\u{2014}"
}
