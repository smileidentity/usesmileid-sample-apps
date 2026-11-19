import AVFoundation
import Njia
import SampleUI
import SwiftUI

/// The token-scanning step: the shared screen, given the shell's camera, clipboard and minter.
struct UseSmileIDSampleScanTokenHost: View {
  let scope: UseSmileIDSampleStepScope

  @EnvironmentObject private var navigation: UseSmileIDSampleNavigationModel
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var torchOn = false

  /// Claimed on arrival, so leaving by any route drops it and a later scan resurrects nothing.
  @State private var resuming: UseSmileIDSampleRunIntent?
  /// So the resume waits for a *different* session.
  @State private var arrivedWith: String?
  @State private var resumeHandled = false
  @State private var arrivedEnded = false
  /// False until the push lands, so a second tap on the nav pill's Token button cannot land on Simulate.
  @State private var settled = false

  var body: some View {
    ScanTokenScreen(
      entry: $app.scanEntry,
      // The redirect's message belongs to the screen it arrives at.
      reason: resuming == nil ? nil : (arrivedEnded ? .sessionEnded : .sessionNeeded),
      torchOn: torchOn,
      onBack: scope.navigator.back,
      onLink: link,
      onSimulate: { span, bindings, environment in
        let minted = UseSmileIDSampleFlowTokens.session(span: span, bindings: bindings, environment: environment, now: Date())
        // The minter and decoder have to agree: a fixture that no longer decodes is a defect, not a session to fabricate.
        if let session = UseSmileIDSampleTokenDecoder.session(minted) {
          link(session)
        }
      },
      // Read behind the tap and never earlier: iOS 16+ prompts on a read the person did not initiate.
      onPaste: { UIPasteboard.general.string },
      onTorchToggle: { torchOn.toggle() },
      viewfinder: viewfinder,
      acceptsTaps: settled
    )
    .background(UseSmileIDSampleTransitionEnd { settled = true })
    .onAppear(perform: claim)
    // Not `sessionActive`, whose clock read would fire once a second.
    .onChange(of: app.session?.id) { _ in resume() }
  }

  /// The camera lives in the shell, `SampleUI` running under eight identities; absent, the screen keeps the glyph.
  private var viewfinder: UseSmileIDSampleViewfinder? {
    guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else { return nil }
    let torchOn = torchOn
    return { enabled, onCandidate in
      AnyView(UseSmileIDSampleQrScanner(onCode: onCandidate, torchOn: torchOn, enabled: enabled))
    }
  }

  private func claim() {
    guard resuming == nil else { return }
    arrivedWith = app.session?.id
    arrivedEnded = app.sessionExpired
    resuming = app.interruptedRun
    app.interruptedRun = nil
  }

  /// Typed, pasted or simulated, a session is linked the same way.
  private func link(_ session: UseSmileIDSampleTokenSession) {
    app.linkSession(session)
    // A resumed run leaves on the change below, once the write has reached the app state.
    if resuming == nil {
      app.runPartnerId = session.partnerId
      scope.navigator.back()
    }
  }

  /// Only on a *different* session: re-entering against the one that sent us here would bounce back.
  private func resume() {
    guard let resuming, !resumeHandled, let linked = app.session, linked.id != arrivedWith else { return }
    resumeHandled = true
    guard !linked.hasExpired(at: Date()) else {
      // An expired relink cannot start the run, and freezing on "linked" says nothing.
      scope.navigator.back()
      return
    }
    let intoFlow = resuming.resumesInFlow(runPartnerId: app.runPartnerId, linkedPartnerId: linked.partnerId)
    app.runPartnerId = linked.partnerId
    guard let product = UseSmileIDSampleProduct.allCases.first(where: { $0.id == resuming.productId }) else {
      scope.navigator.back()
      return
    }
    let engine = navigation.engine
    let run = intoFlow ? app.runOnly(product, route: resuming.route) : app.runEntry(in: engine.graph, for: product)
    // In the scanner's place, so a second quick link is stale against an entry that has gone.
    engine.startRun(from: scope.entry, product: product, run: run, replace: scope.entry.id)
  }
}
