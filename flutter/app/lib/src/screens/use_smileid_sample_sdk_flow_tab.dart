import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

import '../flow/use_smileid_sample_flow_builder_config.dart';
import '../flow/use_smileid_sample_flow_launch_snapshot.dart';
import '../flow/use_smileid_sample_flow_preflight.dart';
import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../state/use_smileid_sample_flow_result_provider.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';

/// The single route hosting the SDK flow. The SDK owns everything inside it: no host chrome, no host back.
class UseSmileIDSampleSdkFlowTab extends ConsumerStatefulWidget {
  /// [productId] comes from the route and decides the whole journey.
  const UseSmileIDSampleSdkFlowTab({
    required this.productId,
    required this.onLeave,
    required this.onNeedsDetails,
    required this.onNeedsSession,
    required this.onResult,
    super.key,
  });

  /// The product this run submits.
  final String productId;

  /// Where a cancelled, failed or never-started run lands.
  final VoidCallback onLeave;

  /// Where a run the forms can still fix goes instead of the SDK.
  final VoidCallback onNeedsDetails;

  /// Where a run whose session has ended goes.
  final VoidCallback onNeedsSession;

  /// Where a delivered result lands, by the job id the server issued.
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

  @override
  void initState() {
    super.initState();
    _jobs = ref.read(useSmileIDSampleJobsProvider.notifier);
    _result = ref.read(useSmileIDSampleFlowResultProvider.notifier);
    // Once at entry: the SDK answers a rebuilt configuration by tearing the run down.
    final UseSmileIDSampleFlowLaunchSnapshot? snapshot = _buildSnapshot();
    _snapshot = snapshot;
    _preflight = snapshot == null ? null : useSmileIDSamplePreflight(snapshot);
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
        );
        if (snapshot.scenario == UseSmileIDSampleScenario.noCallback) {
          return;
        }
        builder.onResult = (UseSmileIDResult<JobSubmissionResponse> result) {
          // Before the throw: the throwing scenario still delivered, and the count must say so.
          _record(result);
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
    final UseSmileIDSampleProfile profile = ref
        .read(useSmileIDSampleProfilesProvider)
        .active;
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
    return UseSmileIDSampleFlowLaunchSnapshot(
      product: product,
      route: ref.read(useSmileIDSampleLaunchArgsProvider).route,
      userDetails: forms.userDetails,
      idDetails: forms.idDetails,
      scenario: scenarios.scenario,
      theme: scenarios.theme,
      sandbox: useSmileIDSampleUseSandbox(session),
      allowAgentMode: settings.agentMode,
      enableEnhancedLiveness: settings.enhancedSmartSelfie,
      consentStep: settings.consentStep,
      instructionsStep: settings.instructionsStep,
      previewStep: settings.previewStep,
      userId: _runUserId(),
      partnerId: profile.id,
      partnerName: profile.organisation,
      callbackUrl: profile.callbackUrl,
      session: session,
      sessionExpired: useSmileIDSampleSessionEnded(record, entryMillis),
    );
  }

  String _runUserId() =>
      'user_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

  void _actOnPreflight() {
    if (!mounted) {
      return;
    }
    switch (_preflight) {
      // A product id this build does not know exits like a mistyped link.
      case null:
        _leave();
      case UseSmileIDSampleFlowReady():
        _result.start(_snapshot!);
      case UseSmileIDSampleFlowNeedsDetails():
        _left = true;
        widget.onNeedsDetails();
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
      // No form fixes this, and it must still never reach the SDK.
      case UseSmileIDSampleFlowMisconfigured(
        :final List<UseSmileIDValidationException> issues,
      ):
        _result.block(
          _snapshot!,
          issues.isEmpty
              ? 'The flow did not validate'
              : issues
                    .map((UseSmileIDValidationException it) => it.message)
                    .join('; '),
        );
        _leave();
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
        if (!_left) {
          _left = true;
          widget.onResult(value.jobId);
        }
      case UseSmileIDFailure<JobSubmissionResponse>():
      case UseSmileIDCancelled<JobSubmissionResponse>():
        _leave();
    }
  }

  void _record(UseSmileIDResult<JobSubmissionResponse> result) {
    switch (result) {
      case UseSmileIDSuccess<JobSubmissionResponse>(
        :final JobSubmissionResponse value,
      ):
        _result.record(
          UseSmileIDSampleFlowStatus.succeeded,
          jobId: value.jobId,
          userId: value.userId,
        );
      case UseSmileIDFailure<JobSubmissionResponse>(:final Exception error):
        _result.record(
          UseSmileIDSampleFlowStatus.failed,
          error: error is UseSmileIDException ? error.message : '$error',
        );
      case UseSmileIDCancelled<JobSubmissionResponse>():
        _result.record(UseSmileIDSampleFlowStatus.cancelled);
    }
  }

  void _leave() {
    if (_left) {
      return;
    }
    _left = true;
    widget.onLeave();
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
