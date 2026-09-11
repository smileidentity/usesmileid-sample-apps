import SwiftUI

/// Why the scanner opened; typed and worded here so the goldens pin it and the eight hosts cannot differ.
public enum UseSmileIDSampleScanReason: Equatable, Sendable {
  case sessionEnded

  public var caption: String {
    switch self {
    case .sessionEnded: "Token session ended. Scan to continue where you left off."
    }
  }
}

/// The host's camera preview, given the sheet's own candidate handler so scanned, pasted and typed share one decode.
public typealias UseSmileIDSampleViewfinder = (_ enabled: Bool, _ onCandidate: @escaping (String) -> Void) -> AnyView

/// Scan token: camera, hand or simulated scan, each linking a session only after the token decodes; with no viewfinder the screen keeps the glyph.
public struct ScanTokenScreen: View {
  @Binding private var entry: UseSmileIDSampleScanSheetState
  private let reason: UseSmileIDSampleScanReason?
  private let torchOn: Bool
  private let onBack: () -> Void
  private let onLink: (UseSmileIDSampleTokenSession) -> Void
  private let onSimulate: (UseSmileIDSampleSimulatedSpan, UseSmileIDSampleSimulatedBindings, UseSmileIDSampleEnvironment) -> Void
  private let onPaste: () -> String?
  private let onTorchToggle: () -> Void
  private let viewfinder: UseSmileIDSampleViewfinder?

  @State private var scan: UseSmileIDSampleScanState = .searching
  /// Held apart from the display state: the credential has no business in something a pill renders.
  @State private var linked: UseSmileIDSampleTokenSession?
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    entry: Binding<UseSmileIDSampleScanSheetState>,
    reason: UseSmileIDSampleScanReason? = nil,
    torchOn: Bool = false,
    onBack: @escaping () -> Void,
    onLink: @escaping (UseSmileIDSampleTokenSession) -> Void,
    onSimulate: @escaping (UseSmileIDSampleSimulatedSpan, UseSmileIDSampleSimulatedBindings, UseSmileIDSampleEnvironment) -> Void,
    onPaste: @escaping () -> String?,
    onTorchToggle: @escaping () -> Void = {},
    viewfinder: UseSmileIDSampleViewfinder? = nil
  ) {
    _entry = entry
    self.reason = reason
    self.torchOn = torchOn
    self.onBack = onBack
    self.onLink = onLink
    self.onSimulate = onSimulate
    self.onPaste = onPaste
    self.onTorchToggle = onTorchToggle
    self.viewfinder = viewfinder
  }

  public var body: some View {
    VStack(spacing: 0) {
      UseSmileIDSampleTopAppBar(title: "Scan token", onBack: onBack) {
        UseSmileIDSampleTopAppBarButton(
          label: torchOn ? "Turn flash off" : "Turn flash on",
          emphasis: .filled,
          action: onTorchToggle
        ) { tint in
          // A bolt like the Compose twin; the shared icon set has none, so the SF Symbol as SearchField does.
          Image(systemName: "bolt.fill")
            .foregroundColor(tint)
        }
      }
      if let viewfinder {
        camera(viewfinder)
      } else {
        // Scrolls because the glyph is fixed: at 2x its copy no longer fits above the sheet.
        GeometryReader { geometry in
          ScrollView {
            VStack(spacing: SmileSpacing.spacingSm) {
              UseSmileIDSampleScanGlyph()
              copy
            }
            .padding(SmileSpacing.spacingMd)
            // The minimum is what centres it: a scroll view alone pins short content to the top.
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
          }
        }
      }
      UseSmileIDSampleScanSheet(
        state: $entry,
        onPaste: paste,
        onLink: { judge(entry.token, fromField: true) },
        onSimulate: { onSimulate(entry.span, entry.bindings, entry.environment) }
      )
    }
    .background(colors.background)
    // A container that contains, so the id sits on the screen without replacing its children's.
    .accessibilityElement(children: .contain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.scanTokenScreen)
    // Acknowledged in the hand as well as on screen: on a held-up scanner a silent success feels like a freeze.
    .task(id: scan) { await acknowledge(scan) }
  }

  private func camera(_ viewfinder: @escaping UseSmileIDSampleViewfinder) -> some View {
    GeometryReader { geometry in
      let searching = scan == .searching
      // Sized to the space, not the design's fixed 279pt: the sheet takes the lower half here.
      let reticleSize = min(geometry.size.width * Self.reticleWidthFraction, geometry.size.height * Self.reticleHeightFraction)
      ZStack {
        viewfinder(searching) { judge($0, fromField: false) }
        VStack(spacing: SmileSpacing.spacingMd) {
          // 45% at rest, firming to full strength the moment the scanner has something.
          UseSmileIDSampleScanGlyph(size: reticleSize, tint: reticleTint, reticle: searching)
            .animation(.default, value: searching)
          if searching {
            // Straight on the camera: a container here was a white slab over the preview.
            copy(color: colors.textInverse, shadow: true)
          } else {
            UseSmileIDSampleScanStatus(state: scan) {
              // Re-enables the scanner, clearing its last-seen code so the same QR reads.
              entry.rejection = nil
              scan = .searching
            }
          }
        }
        .padding(SmileSpacing.spacingMd)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }

  private var copy: some View {
    copy(color: nil, shadow: false)
  }

  @ViewBuilder
  private func copy(color: Color?, shadow: Bool) -> some View {
    UseSmileIDSampleText(Self.title, style: UseSmileIDSampleTheme.type.textStyleTitle)
      .foregroundColor(color ?? colors.textTitle)
      .shadow(color: shadow ? colors.textTitle : .clear, radius: shadow ? Self.copyShadowBlur : 0)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
    UseSmileIDSampleText(reason?.caption ?? Self.caption, style: UseSmileIDSampleTheme.type.textStyleCaption.with(size: 12.5))
      .foregroundColor(color ?? colors.textMuted)
      .shadow(color: shadow ? colors.textTitle : .clear, radius: shadow ? Self.copyShadowBlur : 0)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
  }

  /// The reticle answers with colour before anyone reads the words.
  private var reticleTint: Color {
    switch scan {
    case .searching: colors.textInverse
    case .found: colors.infoFill
    case .linked: colors.successFill
    case .rejected: colors.errorFill
    }
  }

  /// Every candidate is judged here; decoding is not verification, so this proves the token parses, never that it is valid.
  private func judge(_ candidate: String, fromField: Bool) {
    if !fromField {
      scan = .found
    }
    switch UseSmileIDSampleTokenDecoder.decode(candidate) {
    case .decoded(let session):
      entry.rejection = nil
      linked = session
      scan = .linked(handle: session.id, remaining: useSmileIDSampleCountdown(session.remaining(at: Date())))
    // A typed error sits under the field; a scanned one has no field, so it answers in the status pill. Never both.
    case .rejected(let reason):
      if fromField {
        entry.rejection = reason
      } else {
        scan = .rejected(reason: reason)
      }
    }
  }

  private func paste() {
    guard let pasted = onPaste(), !pasted.isBlank else {
      entry.rejection = "The clipboard holds no text to paste."
      return
    }
    entry.token = pasted
    entry.rejection = nil
  }

  private func acknowledge(_ state: UseSmileIDSampleScanState) async {
    switch state {
    case .searching:
      break
    case .found:
      UISelectionFeedbackGenerator().selectionChanged()
    case .rejected:
      UINotificationFeedbackGenerator().notificationOccurred(.error)
    case .linked:
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      // Held long enough to read: navigating on the decode's own frame made a successful scan look like nothing.
      try? await Task.sleep(nanoseconds: Self.linkedDwellNanoseconds)
      guard !Task.isCancelled, let linked else { return }
      onLink(linked)
    }
  }

  private static let title = "Point at a Smile token QR"
  private static let caption = "Line up the code inside the frame to link this device to a verification session."
  /// Long enough to read "Session linked" and its handle, short enough not to feel like a wait.
  private static let linkedDwellNanoseconds: UInt64 = 900000000
  private static let reticleWidthFraction: CGFloat = 0.72
  private static let reticleHeightFraction: CGFloat = 0.52
  private static let copyShadowBlur: CGFloat = 8
}
