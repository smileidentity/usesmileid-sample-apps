import 'package:flutter/foundation.dart';

import 'use_smileid_sample_environment.dart';
import 'use_smileid_sample_scenario.dart';

/// One route, two presentations.
enum UseSmileIDSampleFlowRoute {
  /// The flow covers the shell.
  fullscreen('fullscreen'),

  /// The flow is nested inside the shell, which is the presentation that exposes inset defects.
  shell('shell');

  const UseSmileIDSampleFlowRoute(this.id);

  /// The id automation passes and the result card publishes.
  final String id;

  /// Resolves an id from a launch argument, falling back rather than throwing on a rename.
  static UseSmileIDSampleFlowRoute? byId(String? id) =>
      values.where((UseSmileIDSampleFlowRoute it) => it.id == id).firstOrNull;
}

/// Cancelled and Failed stay separate: a screenshot cannot tell a user backing out from a failure.
enum UseSmileIDSampleFlowStatus {
  /// Nothing has run.
  idle('idle'),

  /// A flow is in flight.
  running('running'),

  /// The flow returned a result.
  succeeded('succeeded'),

  /// The user backed out.
  cancelled('cancelled'),

  /// The flow failed.
  failed('failed');

  const UseSmileIDSampleFlowStatus(this.id);

  /// The id the result card publishes.
  final String id;
}

/// A snapshot of what the SDK did, mirroring `spec/result-card.schema.json` field for field.
@immutable
class UseSmileIDSampleResult {
  /// Takes every field the card renders; the counters are required because zero is a real reading.
  const UseSmileIDSampleResult({
    required this.activeScenario,
    required this.activeTheme,
    required this.route,
    required this.environment,
    required this.jobStatus,
    required this.resultCallbackCount,
    required this.refreshCallbackCount,
    this.jobId,
    this.userId,
    this.lastError,
    this.sdkVersion,
  });

  /// The flow scenario actually in effect, not the one that was asked for.
  final UseSmileIDSampleScenario activeScenario;

  /// The theme scenario in effect.
  final UseSmileIDSampleThemeScenario activeTheme;

  /// The entry route hosting the flow.
  final UseSmileIDSampleFlowRoute route;

  /// Where the run submitted, from its token; the only surface that publishes it.
  final UseSmileIDSampleEnvironment environment;

  /// The current status, including the terminal distinction between cancelled and failed.
  final UseSmileIDSampleFlowStatus jobStatus;

  /// Times the host result callback fired; 'fires exactly once' is only provable by counting.
  final int resultCallbackCount;

  /// Times the token refresh callback fired.
  final int refreshCallbackCount;

  /// The job id the SDK returned, null before a submission completes.
  final String? jobId;

  /// The user id read back from the server response, never a locally generated placeholder.
  final String? userId;

  /// The last error surfaced to the host, code and message.
  final String? lastError;

  /// The SDK version resolved at runtime, which proves which published artifact the run exercised.
  final String? sdkVersion;

  /// Nothing run yet: sandbox, as every tokenless and automated run is.
  static const UseSmileIDSampleResult idle = UseSmileIDSampleResult(
    activeScenario: UseSmileIDSampleScenario.normal,
    activeTheme: UseSmileIDSampleThemeScenario.brandDefault,
    route: UseSmileIDSampleFlowRoute.fullscreen,
    environment: UseSmileIDSampleEnvironment.sandbox,
    jobStatus: UseSmileIDSampleFlowStatus.idle,
    resultCallbackCount: 0,
    refreshCallbackCount: 0,
  );

  /// Whether a flow is in flight.
  bool get inFlight => jobStatus == UseSmileIDSampleFlowStatus.running;

  /// A run starting; both counts reset, so "exactly once" holds per run rather than per launch.
  UseSmileIDSampleResult started({
    required UseSmileIDSampleScenario scenario,
    required UseSmileIDSampleThemeScenario theme,
    required UseSmileIDSampleFlowRoute route,
    required UseSmileIDSampleEnvironment environment,
  }) => UseSmileIDSampleResult(
    activeScenario: scenario,
    activeTheme: theme,
    route: route,
    environment: environment,
    jobStatus: UseSmileIDSampleFlowStatus.running,
    resultCallbackCount: 0,
    refreshCallbackCount: 0,
    sdkVersion: sdkVersion,
  );

  /// One host result callback; [userId] must be the server's, never a local placeholder.
  UseSmileIDSampleResult recorded(
    UseSmileIDSampleFlowStatus status, {
    String? jobId,
    String? userId,
    String? error,
  }) => _with(
    jobStatus: status,
    resultCallbackCount: resultCallbackCount + 1,
    jobId: jobId,
    userId: userId,
    lastError: error,
  );

  /// The gate refused the run, so the SDK never mounted; not a result callback.
  UseSmileIDSampleResult blocked(
    String reason, {
    required UseSmileIDSampleScenario scenario,
    required UseSmileIDSampleThemeScenario theme,
    required UseSmileIDSampleFlowRoute route,
    required UseSmileIDSampleEnvironment environment,
  }) => UseSmileIDSampleResult(
    activeScenario: scenario,
    activeTheme: theme,
    route: route,
    environment: environment,
    jobStatus: UseSmileIDSampleFlowStatus.failed,
    resultCallbackCount: resultCallbackCount,
    refreshCallbackCount: refreshCallbackCount,
    lastError: reason,
    sdkVersion: sdkVersion,
  );

  /// One token refresh callback.
  UseSmileIDSampleResult refreshed() =>
      _with(refreshCallbackCount: refreshCallbackCount + 1);

  /// The drawer's selection, shown until a run records the one it actually got.
  UseSmileIDSampleResult selecting(
    UseSmileIDSampleScenario scenario,
    UseSmileIDSampleThemeScenario theme,
  ) => jobStatus == UseSmileIDSampleFlowStatus.idle
      ? UseSmileIDSampleResult(
          activeScenario: scenario,
          activeTheme: theme,
          route: route,
          environment: environment,
          jobStatus: jobStatus,
          resultCallbackCount: resultCallbackCount,
          refreshCallbackCount: refreshCallbackCount,
          sdkVersion: sdkVersion,
        )
      : this;

  UseSmileIDSampleResult _with({
    UseSmileIDSampleFlowStatus? jobStatus,
    int? resultCallbackCount,
    int? refreshCallbackCount,
    String? jobId,
    String? userId,
    String? lastError,
  }) => UseSmileIDSampleResult(
    activeScenario: activeScenario,
    activeTheme: activeTheme,
    route: route,
    environment: environment,
    jobStatus: jobStatus ?? this.jobStatus,
    resultCallbackCount: resultCallbackCount ?? this.resultCallbackCount,
    refreshCallbackCount: refreshCallbackCount ?? this.refreshCallbackCount,
    // A recorded result replaces all three; a refresh keeps them.
    jobId: jobStatus == null ? this.jobId : jobId,
    userId: jobStatus == null ? this.userId : userId,
    lastError: jobStatus == null ? this.lastError : lastError,
    sdkVersion: sdkVersion,
  );

  /// What the card renders, keyed by the schema's own field names — the spec test reads these keys,
  /// so a field that never reaches the card cannot pass as present.
  Map<String, Object?> toMap() => <String, Object?>{
    'activeScenario': activeScenario.id,
    'activeTheme': activeTheme.id,
    'route': route.id,
    'environment': environment.id,
    'jobId': jobId,
    'userId': userId,
    'jobStatus': jobStatus.id,
    'resultCallbackCount': resultCallbackCount,
    'refreshCallbackCount': refreshCallbackCount,
    'lastError': lastError,
    'sdkVersion': sdkVersion,
  };
}
