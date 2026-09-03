import SwiftUI

/// What the sheet edits. Lifted to the app state by the shell, because one tab is mounted at a time
/// and anything typed has to survive the screen that took it (R6).
public struct UseSmileIDSampleScanSheetState: Equatable, Sendable {
  public var token: String
  /// Why the entered token is not a session — shown under the field, never the token itself.
  public var rejection: String?
  public var span: UseSmileIDSampleSimulatedSpan
  /// Which host the minted token's `api_url` will name.
  public var environment: UseSmileIDSampleEnvironment
  public var bindings: UseSmileIDSampleSimulatedBindings
  /// The mint controls start closed so the viewfinder keeps its height.
  public var expanded: Bool

  public init(
    token: String = "",
    rejection: String? = nil,
    span: UseSmileIDSampleSimulatedSpan = .fifteenMinutes,
    environment: UseSmileIDSampleEnvironment = .sandbox,
    bindings: UseSmileIDSampleSimulatedBindings = UseSmileIDSampleSimulatedBindings(),
    expanded: Bool = false
  ) {
    self.token = token
    self.rejection = rejection
    self.span = span
    self.environment = environment
    self.bindings = bindings
    self.expanded = expanded
  }
}

/// The sheet under the scanner: manual entry, and a simulated scan that mints its own fixture token.
/// Simulate is a product feature, not scaffolding — it is how a flow reaches the session states with
/// no QR source, and what it mints is chosen here rather than hard-coded.
public struct UseSmileIDSampleScanSheet: View {
  @Binding private var state: UseSmileIDSampleScanSheetState
  private let onPaste: () -> Void
  private let onLink: () -> Void
  private let onSimulate: () -> Void

  @ScaledMetric(relativeTo: .body) private var actionHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors
  @Environment(\.sizeCategory) private var sizeCategory

  public init(
    state: Binding<UseSmileIDSampleScanSheetState>,
    onPaste: @escaping () -> Void,
    onLink: @escaping () -> Void,
    onSimulate: @escaping () -> Void
  ) {
    _state = state
    self.onPaste = onPaste
    self.onLink = onLink
    self.onSimulate = onSimulate
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleTextInput(
        value: Binding(
          get: { state.token },
          set: { token in
            state.token = token
            state.rejection = nil
          }
        ),
        placeholder: "Or enter token manually",
        isError: state.rejection != nil,
        errorMessage: state.rejection,
        // The token is a bearer credential and 900 characters long: nobody proofreads it, and
        // masked it stays out of screenshots and out of a failed run's hierarchy dump.
        masked: true,
        testId: UseSmileIDSampleTestIds.tokenManualEntry
      ) {
        UseSmileIDSampleIcon(SmileIcons.tokenScan, tint: colors.input.placeholder, size: SmileSpacing.sizeIconMd)
      } trailing: {
        // Beside the field until type grows; then below it, or the placeholder breaks mid-word.
        if !sizeCategory.isAccessibilityCategory {
          pasteAction
        }
      }
      if sizeCategory.isAccessibilityCategory {
        pasteAction.frame(maxWidth: .infinity, alignment: .trailing)
      }
      // Only once there is something to link, so the default sheet keeps the design's two rows.
      if !state.token.isBlank {
        UseSmileIDSampleButton(text: "Link token", action: onLink)
      }
      // Collapsed by default, and that is the point: this is a scanner, and the mint controls are a
      // probe affordance. Expanded they took enough height to leave the viewfinder a letterbox.
      Button {
        state.expanded.toggle()
      } label: {
        HStack(spacing: SmileSpacing.spacingXs) {
          UseSmileIDSampleSectionLabel("SIMULATED SCAN")
            .frame(maxWidth: .infinity, alignment: .leading)
          UseSmileIDSampleIcon(
            state.expanded ? SmileIcons.chevronDown : SmileIcons.chevron,
            tint: colors.textMuted,
            size: SmileSpacing.sizeIconMd
          )
        }
        .padding(.vertical, SmileSpacing.spacingXxs)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      if state.expanded {
        mintControls
      }
      UseSmileIDSampleButton(
        text: "Simulate a successful scan",
        testId: UseSmileIDSampleTestIds.tokenSimulate,
        action: onSimulate
      )
    }
    .padding(SmileSpacing.spacingMd)
    .frame(maxWidth: .infinity)
    // Its ideal height, not a share of what is left: compressed, its texts truncate at large type.
    .fixedSize(horizontal: false, vertical: true)
    .background(
      UseSmileIDSampleTopRoundedShape(radius: UseSmileIDSampleShapes.sheet)
        .fill(colors.surface)
        .ignoresSafeArea(edges: .bottom)
    )
  }

  private var pasteAction: some View {
    Button(action: onPaste) {
      UseSmileIDSampleText("Paste", style: UseSmileIDSampleTheme.type.linkFont.with(size: 13, weight: 700))
        .foregroundColor(colors.primary)
        .lineLimit(1)
        .padding(.horizontal, SmileSpacing.spacingXs)
        .frame(minHeight: actionHeight)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.tokenPaste)
  }

  @ViewBuilder
  private var mintControls: some View {
    chipRow {
      ForEach(UseSmileIDSampleSimulatedSpan.allCases, id: \.self) { span in
        ScanSheetChip(label: span.label, selected: state.span == span) { state.span = span }
      }
    }
    // Minting is where a run picks an environment, because there is no app-side control left.
    chipRow {
      ForEach(UseSmileIDSampleEnvironment.allCases, id: \.self) { environment in
        ScanSheetChip(
          label: environment.label,
          selected: state.environment == environment,
          testId: UseSmileIDSampleTestIds.tokenEnvironment(environment.id)
        ) { state.environment = environment }
      }
    }
    chipRow {
      ScanSheetChip(label: "Binds consent", selected: state.bindings.consent) { state.bindings.consent.toggle() }
      ScanSheetChip(label: "Binds details", selected: state.bindings.userDetails) { state.bindings.userDetails.toggle() }
    }
  }

  /// Stacks once type grows; SwiftUI has no FlowRow on this floor, so the switch is explicit.
  @ViewBuilder
  private func chipRow(@ViewBuilder _ chips: () -> some View) -> some View {
    if sizeCategory.isAccessibilityCategory {
      VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) { chips() }
    } else {
      HStack(spacing: SmileSpacing.spacingXs) { chips() }
    }
  }
}

/// The filter chip's shape without its count, because what a simulated scan mints has no count.
private struct ScanSheetChip: View {
  let label: String
  let selected: Bool
  var testId: String?
  let onTap: () -> Void

  @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = SmileSpacing.space32
  @ScaledMetric(relativeTo: .body) private var touchHeight: CGFloat = SmileSpacing.sizeControlMd
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    Button(action: onTap) {
      UseSmileIDSampleText(label, style: UseSmileIDSampleTheme.type.filterChipFont.with(size: 13, weight: 700))
        .foregroundColor(selected ? colors.onPrimary : colors.filterChip.label)
        .padding(.horizontal, SmileSpacing.spacingSm)
        .padding(.vertical, SmileSpacing.spacingXs)
        .frame(minHeight: minHeight)
        .background(
          RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.chip, style: .continuous)
            .fill(selected ? colors.primary : colors.filterChip.background)
        )
        .overlay(
          RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.chip, style: .continuous)
            .strokeBorder(selected ? .clear : colors.filterChip.border, lineWidth: SmileSpacing.borderWidthHairline)
        )
        // The platform's touch target around the design's 32pt chip.
        .frame(minHeight: touchHeight)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    .useSmileIDSampleTestId(testId)
  }
}

/// A surface rounded on its top corners only, which the iOS 15 floor has no shape for.
struct UseSmileIDSampleTopRoundedShape: Shape {
  let radius: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
    path.addArc(
      center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
      radius: radius,
      startAngle: .degrees(180),
      endAngle: .degrees(270),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
    path.addArc(
      center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
      radius: radius,
      startAngle: .degrees(270),
      endAngle: .degrees(0),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}
