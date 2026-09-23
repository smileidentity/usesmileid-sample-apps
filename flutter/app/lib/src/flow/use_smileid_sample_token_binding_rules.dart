import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

/// The two scenarios that are about refresh, which a scanned token has no journey for.
bool useSmileIDSampleStartsExpired(UseSmileIDSampleScenario scenario) =>
    scenario == UseSmileIDSampleScenario.expiredToken ||
    scenario == UseSmileIDSampleScenario.badRefresh;

/// The live-session rule in one place; the two refresh scenarios drop the token, and a plain read passes none.
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

/// Whether a session ran out: its marker is stored, or the live token is past its deadline and not yet retired.
bool useSmileIDSampleSessionEnded(
  UseSmileIDSampleSessionRecord record,
  int nowMillis,
) => record.ended != null || (record.live?.hasExpired(nowMillis) ?? false);

/// Drops the issues the token already answers; every other rule the SDK applies still stands.
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
    // The contact rule is reported against the object, so its reason is what identifies it.
    'userDetails' =>
      !requirement.contact && issue.reason.toLowerCase().contains('email'),
    _ => false,
  };
}
