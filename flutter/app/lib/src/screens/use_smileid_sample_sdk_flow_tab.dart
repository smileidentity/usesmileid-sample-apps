import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

import '../catalogue/use_smileid_sample_catalogue_providers.dart';
import '../flow/use_smileid_sample_captured_job.dart';
import '../flow/use_smileid_sample_flow_builder_config.dart';
import '../flow/use_smileid_sample_flow_launch_snapshot.dart';
import '../flow/use_smileid_sample_flow_preflight.dart';
import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../state/use_smileid_sample_flow_result_provider.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_shell_extension.dart';

/// The details entry for a run that never produced a job: the screen shows the run's result instead.
const String unsubmittedJobId = 'unsubmitted';

/// The single route hosting the SDK flow. The SDK owns everything inside it: no host chrome, no host back.
class UseSmileIDSampleSdkFlowTab extends ConsumerStatefulWidget {
  /// [productId] comes from the run's first entry and decides the whole journey.
  const UseSmileIDSampleSdkFlowTab({
    required this.productId,
    required this.route,
    required this.onLeave,
    required this.onNeedsDetails,
    required this.onNeedsSession,
    required this.onNeedsUserId,
    required this.onResult,
    super.key,
  });

  /// The product this run submits.
  final String productId;

  /// Whether the run covers the shell or sits inside it, which its step decides.
  final UseSmileIDSampleFlowRoute route;

  /// Where a cancelled or never-started run lands.
  final VoidCallback onLeave;

  /// Where a run the forms can still fix goes instead of the SDK.
  final VoidCallback onNeedsDetails;

  /// Where a run whose session has ended goes.
  final VoidCallback onNeedsSession;

  /// Where SmartSelfie Authentication goes with no user ID to run as.
  final VoidCallback onNeedsUserId;

  /// Where a run lands: the job id the server issued, or [unsubmittedJobId] for one that failed first.
  final void Function(String jobId) onResult;

  @override
  ConsumerState<UseSmileIDSampleSdkFlowTab> createState() =>
      _UseSmileIDSampleSdkFlowTabState();
}

class _UseSmileIDSampleSdkFlowTabState
    extends ConsumerState<UseSmileIDSampleSdkFlowTab> {
  UseSmileIDSampleFlowLaunchSnapshot? _snapshot;
  UseSmileIDSampleFlowPreflight? _preflight;

  /// Built once: an identical child is not rebuilt when the brightness wrapper above it is.
  Widget? _sdkHost;

  /// A cancel delivered after teardown would otherwise act on whatever replaced this route.
  bool _left = false;

  /// Held from entry: `ref.read` throws once disposed, which is the teardown the write must survive.
  late final UseSmileIDSampleJobsNotifier _jobs;

  /// Held from entry for the same reason as [_jobs]: a teardown-delivered result still counts.
  late final UseSmileIDSampleFlowResultNotifier _result;

  late final UseSmileIDSampleShellExtension? _extension;

  /// Null until the snapshot exists; a run with none never reaches the SDK.
  UseSmileIDSampleRunRecorder? _run;

  @override
  void initState() {
    super.initState();
    _jobs = ref.read(useSmileIDSampleJobsProvider.notifier);
    _result = ref.read(useSmileIDSampleFlowResultProvider.notifier);
    _extension = ref.read(useSmileIDSampleShellExtensionProvider);
    // Once at entry: the SDK answers a rebuilt configuration by tearing the run down.
    final UseSmileIDSampleFlowLaunchSnapshot? snapshot = _buildSnapshot();
    _snapshot = snapshot;
    _run = snapshot == null
        ? null
        : UseSmileIDSampleRunRecorder(_result, snapshot);
    _preflight = snapshot == null
        ? null
        : useSmileIDSamplePreflight(snapshot, extension: _extension);
    // Off the frame, not merely after it: re-adding the shell mid-finalise duplicates its key.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scheduleMicrotask(_actOnPreflight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleFlowLaunchSnapshot? snapshot = _snapshot;
    if (snapshot == null || _preflight is! UseSmileIDSampleFlowReady) {
      // An empty frame: the post-frame callback is already leaving this route.
      return ColoredBox(
        color: UseSmileIDSampleTheme.colorsOf(context).background,
        child: const SizedBox.expand(),
      );
    }
    return _SdkBrightness(child: _sdkHost ??= _sdk(snapshot));
  }

  Widget _sdk(UseSmileIDSampleFlowLaunchSnapshot snapshot) {
    return UseSmileIDBuilder(
      builder: (UseSmileIDFlowBuilder builder) {
        useSmileIDSampleApplying(
          builder,
          snapshot,
          onTokenRefreshed: _result.refreshed,
          extension: _extension,
        );
        _extension?.customiseFlow(builder, snapshot.product);
        if (snapshot.scenario == UseSmileIDSampleScenario.noCallback) {
          return;
        }
        builder.onResult = (UseSmileIDResult<JobSubmissionResponse> result) {
          // Before the throw: the throwing scenario still delivered, and the count must say so.
          _run!.deliverResult(result);
          // Before the throw: a callback that throws must not leave the captured images on disk.
          if (result case UseSmileIDCaptured<JobSubmissionResponse>(
            :final CapturedJob job,
          )) {
            unawaited(job.deleteFiles());
          }
          if (snapshot.scenario == UseSmileIDSampleScenario.throwingCallback) {
            throw StateError(
              'throwingCallback scenario: the host result callback throws',
            );
          }
          _deliver(result, snapshot);
        };
      },
    );
  }

  UseSmileIDSampleFlowLaunchSnapshot? _buildSnapshot() {
    final UseSmileIDSampleProduct? product = UseSmileIDSampleProduct.values
        .where((UseSmileIDSampleProduct it) => it.id == widget.productId)
        .firstOrNull;
    if (product == null) {
      return null;
    }
    final UseSmileIDSampleForms forms = ref.read(useSmileIDSampleFormsProvider);
    final UseSmileIDSampleSettings settings = ref.read(
      useSmileIDSampleSettingsProvider,
    );
    final UseSmileIDSampleScenarioSelection scenarios = ref.read(
      useSmileIDSampleScenarioProvider,
    );
    final UseSmileIDSampleProfiles profiles = ref.read(
      useSmileIDSampleProfilesProvider,
    );
    // Read once, not through the ticking clock: a rebuilt config tears the run down.
    final int entryMillis = DateTime.now().millisecondsSinceEpoch;
    final UseSmileIDSampleSessionRecord record = ref.read(
      useSmileIDSampleSessionProvider,
    );
    // Scenario-free: the environment is the token's even under the refresh scenarios.
    final UseSmileIDSampleTokenSession? session = useSmileIDSampleLiveSession(
      record.live,
      entryMillis,
    );
    final UseSmileIDSampleCatalogueStore catalogue = ref.read(
      useSmileIDSampleCatalogueStoreProvider,
    );
    return UseSmileIDSampleFlowLaunchSnapshot(
      product: product,
      route: widget.route,
      userDetails: forms.userDetails.withoutHiddenNames(
        useSmileIDSampleUserDetailsRequirementFor(
          session?.bindings,
          product,
          catalogue.fieldsToCollectFor(session?.id),
          catalogue.idTypeFieldsFor(session?.id),
        ),
        entry: catalogue
            .idTypeFieldsFor(session?.id)
            .entryFor(
              product,
              forms.idDetails.country?.code,
              forms.idDetails.idType?.type,
            ),
      ),
      idDetails: forms.idDetails,
      scenario: scenarios.scenario,
      theme: scenarios.theme,
      sandbox: useSmileIDSampleUseSandbox(session),
      allowAgentMode: settings.agentMode,
      enableEnhancedLiveness: settings.enhancedSmartSelfie,
      consentStep: settings.consentStep,
      instructionsStep: settings.instructionsStep,
      previewStep: settings.previewStep,
      captureMode: settings.captureMode,
      galleryUpload: settings.galleryUpload,
      allowSkipBack: settings.allowSkipBack,
      selfieFirst: settings.selfieFirst,
      skipApiSubmission: settings.submission.skipsApiSubmission,
      userId: forms.authUserId.trim(),
      partnerId: profiles.partnerId,
      partnerName: profiles.partnerName,
      callbackUrl: profiles.active?.callbackUrl ?? '',
      session: session,
      sessionExpired: useSmileIDSampleSessionEnded(record, entryMillis),
    );
  }

  void _actOnPreflight() {
    if (!mounted) {
      return;
    }
    switch (_preflight) {
      // A product id this build does not know exits like a mistyped link.
      case null:
        _leave();
      case UseSmileIDSampleFlowReady():
        _run!.ensureStarted();
      case UseSmileIDSampleFlowNeedsDetails():
        _left = true;
        widget.onNeedsDetails();
      case UseSmileIDSampleFlowNeedsUserId():
        _left = true;
        widget.onNeedsUserId();
      case UseSmileIDSampleFlowNeedsSession():
        _left = true;
        ref
            .read(useSmileIDSampleInterruptedRunProvider.notifier)
            .send(
              UseSmileIDSampleRunIntent(
                productId: _snapshot!.product.id,
                route: _snapshot!.route,
              ),
            );
        widget.onNeedsSession();
      // No form fixes this, and validate() gives build()'s verdict, so it never reaches the SDK.
      case UseSmileIDSampleFlowMisconfigured(
        :final List<UseSmileIDValidationException> issues,
      ):
        _result.block(
          _snapshot!,
          issues.isEmpty
              ? context.strings.flowInvalid
              : issues
                    .map((UseSmileIDValidationException it) => it.message)
                    .join('; '),
        );
        _land(unsubmittedJobId);
    }
  }

  void _deliver(
    UseSmileIDResult<JobSubmissionResponse> result,
    UseSmileIDSampleFlowLaunchSnapshot snapshot,
  ) {
    switch (result) {
      case UseSmileIDSuccess<JobSubmissionResponse>(
        :final JobSubmissionResponse value,
      ):
        // Held by the provider, not this widget: the write must outlive a same-frame teardown.
        unawaited(_jobs.addJob(_processingJob(snapshot, value)));
        _land(value.jobId);
      case UseSmileIDFailure<JobSubmissionResponse>():
      case UseSmileIDCaptured<JobSubmissionResponse>():
        _land(unsubmittedJobId);
      case UseSmileIDCancelled<JobSubmissionResponse>():
        _leave();
    }
  }

  void _leave() {
    if (_left) {
      return;
    }
    _left = true;
    widget.onLeave();
  }

  /// Lands on a job's details, so a failed or refused run shows its reason rather than a dead tap.
  void _land(String jobId) {
    if (_left) {
      return;
    }
    _left = true;
    widget.onResult(jobId);
  }

  UseSmileIDSampleJob _processingJob(
    UseSmileIDSampleFlowLaunchSnapshot snapshot,
    JobSubmissionResponse response,
  ) => UseSmileIDSampleJob(
    id: response.jobId,
    userId: response.userId,
    product: snapshot.product,
    status: UseSmileIDSampleStatus.processing,
    createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    message: response.message,
    // Accepted, not judged, which is what a finished run writes.
    httpStatus: _acceptedCode,
    // From the snapshot, not re-read: by the time a result lands the toggles may have moved on.
    sandbox: snapshot.sandbox,
    sessionId: snapshot.liveSession?.id,
    partnerId: snapshot.liveSession?.partnerId,
  );

  static const int _acceptedCode = 202;
}

/// The SDK themes itself from the platform brightness, so this hands it the host theme's instead.
class _SdkBrightness extends StatelessWidget {
  const _SdkBrightness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(platformBrightness: Theme.of(context).brightness),
    child: child,
  );
}
