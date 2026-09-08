import SampleUI
import SwiftUI
import UseSmileID

/// The single route hosting the SDK flow, in both presentations (R3). The SDK owns everything inside
/// it (R2): no host back control, no host chrome, and the SDK's own back is what steps through the
/// journey. Where the two presentations differ is the host's insets — `fullscreen` contributes none,
/// which is the Compose twin's `WindowInsets(0)`, and `shell` leaves the flow inside the shell's own
/// safe area, which is the presentation that exposes inset defects.
struct SdkFlowScreen: View {
  let productId: String
  let presentation: UseSmileIDSampleFlowRoute

  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  /// Once per entry: the snapshot is read here and never again, and the run starts once.
  @StateObject private var run = SdkFlowRun()

  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    // A stack with real size, not a background on the content: before the gate has run the content
    // is empty, and SwiftUI drops an empty view's background — with it the signal below never fired.
    ZStack {
      // The app's own ground, so the frame before the SDK mounts is not white.
      colors.background
      content
      // The push is over here; `onAppear` fires inside it, and every gate exit is a path change.
      UseSmileIDSampleTransitionEnd(action: enter).frame(width: 0, height: 0)
    }
    // `fullscreen` contributes no insets, which is the Compose twin's `WindowInsets(0)`; `shell`
    // leaves the flow inside the shell's own safe area.
    .ignoresSafeArea(edges: presentation == .fullscreen ? .all : [])
    .navigationBarHidden(true)
  }

  @ViewBuilder
  private var content: some View {
    if run.stage == .ready, let builder = run.builder {
      builder
    }
  }

  /// §7.3's gate, then the run. Every exit replaces the path rather than popping it, so a repeated
  /// delivery cannot stack a second screen and nothing can go back into capture (R4).
  private func enter() {
    guard run.claimEntry() else { return }
    // Hoisted out of the view: a teardown-delivered cancel arrives from the SDK's own `deinit`, after
    // this level is gone, where reading an `@EnvironmentObject` is no longer valid.
    let app = app
    let router = router
    let run = run
    let flow = Route.sdkFlow(productId: productId, presentation: presentation)
    guard let snapshot = buildSnapshot(
      productId: productId,
      route: presentation,
      app: app,
      // A prior enrolment's id when the card holds one, so authentication has something enrolled.
      userId: app.flowResult.userId ?? UUID().uuidString
    ) else {
      // An unknown product id exits like a mistyped route: there is nothing to run.
      useSmileIDSampleLeaveFlow(router, run, flow)
      return
    }
    switch useSmileIDSamplePreflight(snapshot) {
    case .needsDetails:
      // The form, with the flow gone from underneath it: a deep link seats no form below the run.
      useSmileIDSampleLeaveFlow(router, run, flow, landing: .consentDetailsForm(productId: snapshot.product.id))
    case .needsSession:
      // Back to the scanner, not to a form: the run needs a token, and no form holds one.
      app.interruptedRun = UseSmileIDSampleRunIntent(productId: snapshot.product.id, route: snapshot.route)
      useSmileIDSampleLeaveFlow(router, run, flow, landing: .scanToken)
    case .misconfigured(let issues):
      // No form fixes this, so it exits like a mistyped product id — but says why first: a silent
      // return to the product list is indistinguishable from a dead tap.
      app.flowResult.recordBlocked(reason: issues.joined(separator: "; "), environment: snapshot.environment)
      useSmileIDSampleLeaveFlow(router, run, flow)
    case .ready:
      app.flowResult.startFlow(environment: snapshot.environment)
      let handler = SdkFlowResultHandler(app: app, router: router, run: run, flow: flow, snapshot: snapshot)
      run.start(builder: builder(snapshot, app: app, handler: handler))
    }
  }

  private func builder(
    _ snapshot: FlowLaunchSnapshot,
    app: UseSmileIDSampleAppState,
    handler: SdkFlowResultHandler
  ) -> UseSmileIDBuilder {
    UseSmileIDBuilder { builder in
      useSmileIDSampleApply(builder, snapshot, onTokenRefreshed: { app.flowResult.recordRefreshCallback() })
      // The scenario is the whole point of `noCallback`: the SDK keeps its own default, which does
      // nothing, and the run must neither hang nor crash.
      guard snapshot.scenario != .noCallback else { return }
      builder.onResult = handler.deliver
    }
  }
}

/// The result path, wired at entry and holding no view: the SDK's teardown cancel is delivered from a
/// `deinit`, by which time this level is gone and an `@EnvironmentObject` read is no longer valid.
@MainActor
struct SdkFlowResultHandler {
  let app: UseSmileIDSampleAppState
  let router: UseSmileIDSampleRouter
  let run: SdkFlowRun
  let flow: Route
  let snapshot: FlowLaunchSnapshot

  func deliver(_ result: UseSmileIDResult<JobSubmissionResponse>) {
    record(result)
    switch result {
    case .success(let response):
      app.addJob(processingJob(response), bindings: snapshot.liveSession?.bindings)
      useSmileIDSampleLeaveFlow(router, run, flow, landing: .verificationDetails(jobId: response.jobId))
    // Same destination, showing the error: a failed run has no server-issued job id, so the route
    // carries a stable non-id and the screen says nothing is stored under it.
    case .failure:
      useSmileIDSampleLeaveFlow(router, run, flow, landing: .verificationDetails(jobId: unsubmittedJobId))
    // Popping the flow *is* the cancel, so the host must not fire one of its own.
    case .cancelled:
      useSmileIDSampleLeaveFlow(router, run, flow)
    }
  }

  private func record(_ result: UseSmileIDResult<JobSubmissionResponse>) {
    switch result {
    case .success(let response):
      app.flowResult.recordResultCallback(status: .succeeded, jobId: response.jobId, userId: response.userId)
    case .failure(let error):
      app.flowResult.recordResultCallback(status: .failed, error: error.useSmileIDSampleMessage)
    case .cancelled:
      app.flowResult.recordResultCallback(status: .cancelled)
    }
  }

  private func processingJob(_ response: JobSubmissionResponse) -> UseSmileIDSampleJob {
    UseSmileIDSampleJob(
      id: response.jobId,
      userId: response.userId,
      product: snapshot.product,
      status: .processing,
      createdAt: Date(),
      message: response.message,
      httpStatus: 202,
      // From the snapshot, not re-read: by the time a result lands the session may have moved on.
      sandbox: snapshot.sandbox,
      sessionId: snapshot.liveSession?.id,
      partnerId: snapshot.liveSession?.partnerId
    )
  }
}

/// The one exit: the run stops mounting anything and the path is replaced (R4).
@MainActor
func useSmileIDSampleLeaveFlow(
  _ router: UseSmileIDSampleRouter,
  _ run: SdkFlowRun,
  _ flow: Route,
  landing: Route? = nil
) {
  run.leave()
  router.endFlow(flow, landing: landing)
}

extension Error {
  /// The message the card reports, falling back to the type when an error carries none.
  var useSmileIDSampleMessage: String {
    if let exception = self as? any UseSmileIDException, !exception.message.isEmpty {
      return exception.message
    }
    return localizedDescription.isEmpty ? String(describing: type(of: self)) : localizedDescription
  }
}

/// A failed run has no server-issued job id, so the landing route carries a stable non-id.
private let unsubmittedJobId = "unsubmitted"
