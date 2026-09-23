import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

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

/// Drops the issues the token already answers.
ValidationState useSmileIDSampleMinusRequirement(
  ValidationState state,
  UseSmileIDSampleUserDetailsRequirement requirement,
) {
  if (state is! ValidationStateInvalid) {
    return state;
  }
  final List<UseSmileIDValidationException> outstanding =
      <UseSmileIDValidationException>[
        for (final UseSmileIDValidationException issue in state.issues)
          if (!_covers(requirement, issue)) issue,
      ];
  return outstanding.isEmpty
      ? const ValidationStateValid()
      : ValidationStateInvalid(outstanding);
}

bool _covers(
  UseSmileIDSampleUserDetailsRequirement requirement,
  UseSmileIDValidationException issue,
) {
  if (issue is! InvalidFieldValueException) {
    return false;
  }
  return switch (issue.fieldName) {
    'userDetails.givenNames' => !requirement.firstName,
    'userDetails.lastName' => !requirement.lastName,
    // Reported against the object, so the reason identifies it.
    'userDetails' =>
      !requirement.contact && issue.reason.toLowerCase().contains('email'),
    _ => false,
  };
}
