import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

/// The two scenarios that are about refresh, which a scanned token has no journey for.
bool useSmileIDSampleStartsExpired(UseSmileIDSampleScenario scenario) =>
    scenario == UseSmileIDSampleScenario.expiredToken ||
    scenario == UseSmileIDSampleScenario.badRefresh;

/// The live-session rule in one place, so nothing disagrees about whether a token is live.
UseSmileIDSampleTokenSession? useSmileIDSampleLiveSession(
  UseSmileIDSampleTokenSession? session,
  UseSmileIDSampleScenario scenario,
  int nowMillis,
) =>
    session != null &&
        !session.hasExpired(nowMillis) &&
        !useSmileIDSampleStartsExpired(scenario)
    ? session
    : null;

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
