import 'package:sample_ui/sample_ui.dart';

/// Whether [scenario] is one of the two about refresh.
bool useSmileIDSampleStartsExpired(UseSmileIDSampleScenario scenario) =>
    scenario == UseSmileIDSampleScenario.expiredToken ||
    scenario == UseSmileIDSampleScenario.badRefresh;

/// The session if live at [nowMillis], dropped under a refresh [scenario].
UseSmileIDSampleTokenSession? useSmileIDSampleLiveSession(
  UseSmileIDSampleTokenSession? session,
  int nowMillis, {
  UseSmileIDSampleScenario scenario = UseSmileIDSampleScenario.normal,
}) =>
    session != null &&
        !session.hasExpired(nowMillis) &&
        !useSmileIDSampleStartsExpired(scenario)
    ? session
    : null;

/// Whether the session has ended, by its marker or its deadline.
bool useSmileIDSampleSessionEnded(
  UseSmileIDSampleSessionRecord record,
  int nowMillis,
) => record.ended != null || (record.live?.hasExpired(nowMillis) ?? false);
