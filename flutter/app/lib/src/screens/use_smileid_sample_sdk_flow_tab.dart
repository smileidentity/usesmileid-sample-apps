import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

import '../flow/use_smileid_sample_flow_builder_config.dart';
import '../flow/use_smileid_sample_flow_launch_snapshot.dart';
import '../flow/use_smileid_sample_flow_preflight.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';

/// The single route hosting the SDK flow. The SDK owns everything inside it: no host chrome, no host back.
class UseSmileIDSampleSdkFlowTab extends ConsumerStatefulWidget {
  /// [productId] comes from the route and decides the whole journey.
  const UseSmileIDSampleSdkFlowTab({
    required this.productId,
    required this.onLeave,
    required this.onNeedsDetails,
    required this.onResult,
    super.key,
  });

  /// The product this run submits.
  final String productId;

  /// Where a cancelled, failed or never-started run lands.
  final VoidCallback onLeave;

  /// Where a run the forms can still fix goes instead of the SDK.
  final VoidCallback onNeedsDetails;

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

  /// A teardown-delivered cancel arrives after the route is gone, where leaving again would act on
  /// whatever replaced it.
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Read once at entry and never while the run is in flight: the SDK answers a rebuilt
    // configuration by re-running build() and tearing the run down.
    final UseSmileIDSampleFlowLaunchSnapshot? snapshot = _buildSnapshot();
    _snapshot = snapshot;
    _preflight = snapshot == null ? null : useSmileIDSamplePreflight(snapshot);
    // Off the frame entirely, not merely after it: leaving this route rebuilds the shell, and
    // doing that while the tree is still being finalised re-creates its navigator's global key.
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
    return UseSmileIDBuilder(
      builder: (UseSmileIDFlowBuilder builder) {
        useSmileIDSampleApplying(builder, snapshot);
        if (snapshot.scenario == UseSmileIDSampleScenario.noCallback) {
          return;
        }
        builder.onResult = (UseSmileIDResult<JobSubmissionResponse> result) {
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
    return UseSmileIDSampleFlowLaunchSnapshot(
      product: product,
      route: ref.read(useSmileIDSampleLaunchArgsProvider).route,
      userDetails: forms.userDetails,
      idDetails: forms.idDetails,
      scenario: scenarios.scenario,
      theme: scenarios.theme,
      // Sandbox until a scanned session says otherwise, because the environment is the token's.
      sandbox: true,
      allowAgentMode: settings.agentMode,
      enableEnhancedLiveness: settings.enhancedSmartSelfie,
      consentStep: settings.consentStep,
      instructionsStep: settings.instructionsStep,
      previewStep: settings.previewStep,
      userId: _runUserId(),
      partnerId: profile.id,
      partnerName: profile.organisation,
      // A profile here carries no webhook URL yet, and empty means the partner's portal default.
      callbackUrl: '',
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
        break;
      case UseSmileIDSampleFlowNeedsDetails():
        _left = true;
        widget.onNeedsDetails();
      // No form fixes this, and it must still never reach the SDK.
      case UseSmileIDSampleFlowMisconfigured():
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
        // Awaited by nobody and scoped to the provider rather than this widget: a result the SDK
        // delivers exactly once must be written even if the route is torn down in the same frame.
        unawaited(
          ref
              .read(useSmileIDSampleJobsProvider.notifier)
              .addJob(_processingJob(snapshot, value)),
        );
        if (!_left) {
          _left = true;
          widget.onResult(value.jobId);
        }
      case UseSmileIDFailure<JobSubmissionResponse>():
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
  );

  static const int _acceptedCode = 202;
}
