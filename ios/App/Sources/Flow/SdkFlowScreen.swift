import SampleUI
import SwiftUI
import UseSmileID

/// The single route hosting the SDK flow in both presentations, which differ only in insets; no host chrome inside it.
struct SdkFlowScreen: View {
  let productId: String
  let presentation: UseSmileIDSampleFlowRoute

  @EnvironmentObject private var router: UseSmileIDSampleRouter
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  /// Once per entry: the snapshot is read here and never again.
  @StateObject private var run = SdkFlowRun()

  var body: some View {
    // A stack, not a background: the content is empty until the gate runs, and SwiftUI drops an empty view's background.
    ZStack {
      // The system colour, as a partner host has: capture forces dark, so the preview's safe-area strips read black, not scrim-grey.
      Color(uiColor: .systemBackground)
      content
      // The push is over here: `onAppear` fires inside it, and every gate exit is a path change.
      UseSmileIDSampleTransitionEnd(action: enter).frame(width: 0, height: 0)
      // Mounted with the run: a hold has to overlap it to contend with it.
      if let product = run.product {
        UseSmileIDSampleCameraHold(hold: app.launchArguments.holdCamera, product: product)
      }
    }
    .ignoresSafeArea(edges: presentation == .fullscreen ? .all : [])
    .navigationBarHidden(true)
  }

  @ViewBuilder
  private var content: some View {
    if run.stage == .ready, let builder = run.builder {
      builder
    }
  }

  /// The gate, then the run. Every exit replaces the path rather than popping it (R4).
  private func enter() {
    guard run.claimEntry() else { return }
    // Hoisted: a teardown cancel arrives from the SDK's `deinit`, where an `@EnvironmentObject` read is invalid.
    let app = app
    let router = router
    let run = run
    let flow = Route.sdkFlow(productId: productId, presentation: presentation)
    guard let snapshot = buildSnapshot(
      productId: productId,
      route: presentation,
      app: app,
      // A prior enrolment's id, so authentication has something enrolled.
      userId: app.flowResult.userId ?? UUID().uuidString
    ) else {
      useSmileIDSampleLeaveFlow(router, run, flow)
      return
    }
    switch useSmileIDSamplePreflight(snapshot) {
    case .needsDetails:
      // The flow goes from underneath it: a deep link seats no form below the run.
      useSmileIDSampleLeaveFlow(router, run, flow, landing: .consentDetailsForm(productId: snapshot.product.id))
    case .needsSession:
      // The scanner, not a form: the run needs a token, and no form holds one.
      app.interruptedRun = UseSmileIDSampleRunIntent(productId: snapshot.product.id, route: snapshot.route)
      useSmileIDSampleLeaveFlow(router, run, flow, landing: .scanToken)
    case .misconfigured(let issues):
      // Says why first: a silent return to the product list reads as a dead tap.
      app.flowResult.recordBlocked(reason: issues.joined(separator: "; "), environment: snapshot.environment)
      useSmileIDSampleLeaveFlow(router, run, flow)
    case .ready:
      app.flowResult.startFlow(environment: snapshot.environment)
      let handler = SdkFlowResultHandler(app: app, router: router, run: run, flow: flow, snapshot: snapshot)
      run.start(product: snapshot.product, builder: builder(snapshot, app: app, handler: handler))
    }
  }

  private func builder(
    _ snapshot: FlowLaunchSnapshot,
    app: UseSmileIDSampleAppState,
    handler: SdkFlowResultHandler
  ) -> UseSmileIDBuilder {
    UseSmileIDBuilder { builder in
      useSmileIDSampleApply(builder, snapshot, onTokenRefreshed: { app.flowResult.recordRefreshCallback() })
      // `noCallback` leaves the SDK's own default, which does nothing.
      guard snapshot.scenario != .noCallback else { return }
      builder.onResult = handler.deliver
    }
  }
}

/// Holds no view: the SDK's teardown cancel is delivered from a `deinit`, after this level is gone.
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
    // Same destination: a failed run has no server-issued job id, so the route carries a non-id.
    case .failure:
      useSmileIDSampleLeaveFlow(router, run, flow, landing: .verificationDetails(jobId: unsubmittedJobId))
    // Popping the flow *is* the cancel, so the host fires none of its own.
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
      // From the snapshot: by the time a result lands the session may have moved on.
      sandbox: snapshot.sandbox,
      sessionId: snapshot.liveSession?.id,
      partnerId: snapshot.liveSession?.partnerId
    )
  }
}

/// The one exit: the run mounts nothing more and the path is replaced (R4).
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
  /// What the card reports, falling back to the type when an error carries no message.
  var useSmileIDSampleMessage: String {
    if let exception = self as? any UseSmileIDException, !exception.message.isEmpty {
      return exception.message
    }
    return localizedDescription.isEmpty ? String(describing: type(of: self)) : localizedDescription
  }
}

/// The landing route for a run with no server-issued job id.
private let unsubmittedJobId = "unsubmitted"
