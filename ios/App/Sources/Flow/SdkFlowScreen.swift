import Njia
import SampleUI
import SwiftUI
import UseSmileID

/// The step hosting the SDK flow in both presentations, which differ only in insets; no host chrome inside it.
struct SdkFlowScreen: View {
  let scope: UseSmileIDSampleStepScope

  @EnvironmentObject private var navigation: UseSmileIDSampleNavigationModel
  @EnvironmentObject private var app: UseSmileIDSampleAppState
  /// Once per entry: the snapshot is read here and never again.
  @StateObject private var run = SdkFlowRun()

  @Environment(\.useSmileIDSampleColors) private var colors

  private var presentation: UseSmileIDSampleFlowRoute {
    scope.step.kind == .sdkFlowFullScreen ? .fullscreen : .shell
  }

  var body: some View {
    // A stack, not a background: the content is empty until the gate runs, and SwiftUI drops an empty view's background.
    ZStack {
      colors.background
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

  /// The gate, then the run. Every exit replaces the run rather than popping it (R4).
  private func enter() {
    guard run.claimEntry() else { return }
    // Hoisted: a teardown cancel arrives from the SDK's `deinit`, where an `@EnvironmentObject` read is invalid.
    let app = app
    let exit = SdkFlowExit(engine: navigation.engine, entry: scope.entry, run: run)
    guard let snapshot = buildSnapshot(
      productId: exit.engine.runProductId(scope.entry) ?? "",
      route: presentation,
      app: app
    ) else {
      exit.leave()
      return
    }
    switch useSmileIDSamplePreflight(snapshot) {
    case .needsDetails:
      // The flow goes from underneath it: a deep link seats no form below the run.
      exit.leave(landing: .consentDetailsForm, arg: snapshot.product.id)
    case .needsUserId:
      exit.leave(landing: .authUserId, arg: snapshot.product.id)
    case .needsSession:
      // The scanner, not a form: the run needs a token, and no form holds one.
      app.interruptedRun = UseSmileIDSampleRunIntent(productId: snapshot.product.id, route: snapshot.route)
      exit.leave(landing: .scanToken)
    case .misconfigured(let issues):
      // Says why first: a silent return to the product list reads as a dead tap.
      app.flowResult.recordBlocked(reason: issues.joined(separator: "; "), environment: snapshot.environment)
      exit.leave()
    case .ready:
      app.flowResult.startFlow(environment: snapshot.environment)
      let handler = SdkFlowResultHandler(app: app, exit: exit, snapshot: snapshot)
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
      useSmileIDSampleShellExtension?.customiseFlow(builder, product: snapshot.product)
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
  let exit: SdkFlowExit
  let snapshot: FlowLaunchSnapshot

  func deliver(_ result: UseSmileIDResult<JobSubmissionResponse>) {
    record(result)
    switch result {
    case .success(let response):
      app.addJob(processingJob(response), bindings: snapshot.liveSession?.bindings)
      exit.leave(landing: .verificationDetails, arg: response.jobId)
    // Same destination: a failed run has no server-issued job id, so the route carries a non-id.
    case .failure, .captured:
      exit.leave(landing: .verificationDetails, arg: unsubmittedJobId)
    // Popping the flow *is* the cancel, so the host fires none of its own.
    case .cancelled:
      exit.leave()
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
    // Never expected: this app does not set skipApiSubmission.
    case .captured:
      app.flowResult.recordResultCallback(status: .failed, error: capturedNotSubmitted)
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

/// The one exit: the run mounts nothing more, the products tab drops it, and the landing step opens from its own tab's root (R4).
@MainActor
struct SdkFlowExit {
  let engine: UseSmileIDSampleEngine
  /// The run's entry: an exit once it has left the stack, such as a teardown cancel, is stale and moves nothing.
  let entry: NjiaEntry
  let run: SdkFlowRun

  func leave(landing: UseSmileIDSampleStep? = nil, arg: String? = nil) {
    run.leave()
    guard engine.state.entries.contains(where: { $0.id == entry.id }) else { return }
    engine.leaveToProducts()
    guard let landing else { return }
    let tab = engine.graph.steps.first { $0.kind == landing }?.tab ?? UseSmileIDSampleStep.products.rawValue
    if tab != UseSmileIDSampleStep.products.rawValue {
      // Twice: the first shows the tab as it was left, the second pops it to its root, as a link lands.
      engine.select(tab)
      engine.select(tab)
    }
    engine.top.map { engine.navigator($0).go(landing, arg: arg) }
  }
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

/// Recorded when the SDK hands back a captured job instead of submitting it.
private let capturedNotSubmitted = "Captured, not submitted"
