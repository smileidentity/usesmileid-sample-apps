import AVFoundation
import SampleUI
import SwiftUI

/// The token-scanning route: the shared screen, given the shell's camera, clipboard and minter.
struct UseSmileIDSampleScanTokenHost: View {
  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  @State private var torchOn = false

  var body: some View {
    ScanTokenScreen(
      entry: $app.scanEntry,
      // Nothing sends anyone here mid-journey yet: the expiry gate is not built, so no caller passes a reason.
      reason: nil,
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

  /// One path for every entry route — typed, pasted or simulated, a session is linked the same way.
  private func link(_ session: UseSmileIDSampleTokenSession) {
    app.linkSession(session)
    router.pop()
  }
}
