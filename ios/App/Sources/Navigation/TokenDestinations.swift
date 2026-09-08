import AVFoundation
import SampleUI
import SwiftUI

/// The token-scanning route: the shared screen, given the shell's camera, clipboard and minter.
struct UseSmileIDSampleScanTokenHost: View {
  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var torchOn = false

  /// The run the expiry gate sent here, claimed on arrival: leaving by any route drops it, so a later
  /// scan cannot resurrect a run the reader has walked away from.
  @State private var resuming: UseSmileIDSampleRunIntent?
  /// The session that sent us here, so the resume waits for a *different* one.
  @State private var arrivedWith: String?
  @State private var resumeHandled = false

  var body: some View {
    ScanTokenScreen(
      entry: $app.scanEntry,
      // Why this screen opened, per R10: the redirect's message belongs to the screen it arrives at.
      reason: resuming == nil ? nil : .sessionEnded,
      torchOn: torchOn,
      onBack: { router.pop() },
      onLink: link,
      onSimulate: { span, bindings, environment in
        let minted = UseSmileIDSampleFlowTokens.session(span: span, bindings: bindings, environment: environment, now: Date())
        // The minter and the decoder have to agree, and a fixture that no longer decodes is a defect
        // rather than something to paper over with a fabricated session.
        if let session = UseSmileIDSampleTokenDecoder.session(minted) {
          link(session)
        }
      },
      // Read behind the tap and never earlier: iOS 16+ prompts on a read the person did not initiate.
      onPaste: { UIPasteboard.general.string },
      onTorchToggle: { torchOn.toggle() },
      viewfinder: viewfinder
    )
    .onAppear(perform: claim)
    // Keyed on the session, not on `sessionActive`, whose clock read would fire once a second.
    .onChange(of: app.session?.id) { _ in resume() }
  }

  /// The camera lives in the shell: `SampleUI` runs under eight identities, and only this one owns a
  /// scanner. Absent — every simulator, or a device without one — the screen keeps the glyph.
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
    resuming = app.interruptedRun
    app.interruptedRun = nil
  }

  /// One path for every entry route — typed, pasted or simulated, a session is linked the same way.
  private func link(_ session: UseSmileIDSampleTokenSession) {
    app.linkSession(session)
    // A resumed run leaves on the change below instead, once the write has reached the app state.
    if resuming == nil {
      router.pop()
    }
  }

  /// Re-enters the run the gate interrupted, once a *different* session is linked: re-entering
  /// against the one that sent us here would bounce straight back to this screen.
  private func resume() {
    guard let resuming, !resumeHandled, let linked = app.session, linked.id != arrivedWith else { return }
    resumeHandled = true
    guard !linked.hasExpired(at: Date()) else {
      // An already-expired relink cannot start the run, and the pill offers no retry — so leave
      // rather than freeze on a screen saying "linked".
      router.pop()
      return
    }
    // Opened, not pushed: the path is assigned, so the scanner goes with it and two quick links
    // cannot stack two runs.
    router.open(.sdkFlow(productId: resuming.productId, presentation: resuming.route))
  }
}
