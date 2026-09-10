import AVFoundation
import SampleUI
import SwiftUI

/// The token-scanning route: the shared screen, given the shell's camera, clipboard and minter.
struct UseSmileIDSampleScanTokenHost: View {
  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var torchOn = false

  /// Claimed on arrival, so leaving by any route drops it and a later scan resurrects nothing.
  @State private var resuming: UseSmileIDSampleRunIntent?
  /// So the resume waits for a *different* session.
  @State private var arrivedWith: String?
  @State private var resumeHandled = false

  var body: some View {
    ScanTokenScreen(
      entry: $app.scanEntry,
      // R10: the redirect's message belongs to the screen it arrives at.
      reason: resuming == nil ? nil : .sessionEnded,
      torchOn: torchOn,
      onBack: { router.pop() },
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
      viewfinder: viewfinder
    )
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
    resuming = app.interruptedRun
    app.interruptedRun = nil
  }

  /// Typed, pasted or simulated, a session is linked the same way.
  private func link(_ session: UseSmileIDSampleTokenSession) {
    app.linkSession(session)
    // A resumed run leaves on the change below, once the write has reached the app state.
    if resuming == nil {
      router.pop()
    }
  }

  /// Only on a *different* session: re-entering against the one that sent us here would bounce back.
  private func resume() {
    guard let resuming, !resumeHandled, let linked = app.session, linked.id != arrivedWith else { return }
    resumeHandled = true
    guard !linked.hasExpired(at: Date()) else {
      // An expired relink cannot start the run, and freezing on "linked" says nothing.
      router.pop()
      return
    }
    // Opened, not pushed: the path is assigned, so two quick links cannot stack two runs.
    router.open(.sdkFlow(productId: resuming.productId, presentation: resuming.route))
  }
}
