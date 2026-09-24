import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../flow/use_smileid_sample_flow_launch_snapshot.dart';
import 'use_smileid_sample_providers.dart';

/// What the SDK did on the last run, which the result card publishes.
final NotifierProvider<
  UseSmileIDSampleFlowResultNotifier,
  UseSmileIDSampleResult
>
useSmileIDSampleFlowResultProvider =
    NotifierProvider<
      UseSmileIDSampleFlowResultNotifier,
      UseSmileIDSampleResult
    >(UseSmileIDSampleFlowResultNotifier.new);

/// Debug builds, or a release launched with `probes`, show the full card.
final Provider<bool> useSmileIDSampleShowProbesProvider = Provider<bool>(
  (Ref ref) =>
      kDebugMode || ref.watch(useSmileIDSampleLaunchArgsProvider).probes,
);

/// Held above every route, so a count survives the flow's own teardown.
class UseSmileIDSampleFlowResultNotifier
    extends Notifier<UseSmileIDSampleResult> {
  @override
  UseSmileIDSampleResult build() {
    ref.listen(useSmileIDSampleScenarioProvider, (
      UseSmileIDSampleScenarioSelection? _,
      UseSmileIDSampleScenarioSelection next,
    ) {
      state = state.selecting(next.scenario, next.theme);
    });
    final UseSmileIDSampleScenarioSelection selection = ref.read(
      useSmileIDSampleScenarioProvider,
    );
    return UseSmileIDSampleResult.idle.selecting(
      selection.scenario,
      selection.theme,
    );
  }

  /// The SDK mounted for [snapshot]'s run.
  void start(UseSmileIDSampleFlowLaunchSnapshot snapshot) =>
      state = state.started(
        scenario: snapshot.scenario,
        theme: snapshot.theme,
        route: snapshot.route,
        environment: _environment(snapshot),
      );

  /// One host result callback.
  void record(
    UseSmileIDSampleFlowStatus status, {
    String? jobId,
    String? userId,
    String? error,
  }) => state = state.recorded(
    status,
    jobId: jobId,
    userId: userId,
    error: error,
  );

  /// The gate refused [snapshot]'s run before the SDK mounted.
  void block(UseSmileIDSampleFlowLaunchSnapshot snapshot, String reason) =>
      state = state.blocked(
        reason,
        scenario: snapshot.scenario,
        theme: snapshot.theme,
        route: snapshot.route,
        environment: _environment(snapshot),
      );

  /// One token refresh callback.
  void refreshed() => state = state.refreshed();

  static UseSmileIDSampleEnvironment _environment(
    UseSmileIDSampleFlowLaunchSnapshot snapshot,
  ) => snapshot.sandbox
      ? UseSmileIDSampleEnvironment.sandbox
      : UseSmileIDSampleEnvironment.production;
}

/// One run's link to the card: started exactly once, before its first delivery, whichever comes first.
class UseSmileIDSampleRunRecorder {
  /// Records [snapshot]'s run into [result].
  UseSmileIDSampleRunRecorder(this._result, this._snapshot);

  final UseSmileIDSampleFlowResultNotifier _result;

  final UseSmileIDSampleFlowLaunchSnapshot _snapshot;

  bool _started = false;

  /// Starts the run unless a delivery already did: the SDK can answer on its own first frame.
  void ensureStarted() {
    if (_started) {
      return;
    }
    _started = true;
    _result.start(_snapshot);
  }

  /// One host result callback, counted against this run.
  void deliver(
    UseSmileIDSampleFlowStatus status, {
    String? jobId,
    String? userId,
    String? error,
  }) {
    ensureStarted();
    _result.record(status, jobId: jobId, userId: userId, error: error);
  }
}
