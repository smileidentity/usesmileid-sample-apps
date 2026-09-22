import 'package:flutter/foundation.dart';
import 'package:sample_ui/sample_ui.dart';

/// Read once at flow entry; never re-read while the flow runs.
@immutable
class UseSmileIDSampleFlowLaunchSnapshot {
  /// Takes the five settings rather than the settings object, because the read happens once.
  const UseSmileIDSampleFlowLaunchSnapshot({
    required this.product,
    required this.route,
    required this.userDetails,
    required this.idDetails,
    required this.scenario,
    required this.theme,
    required this.sandbox,
    required this.allowAgentMode,
    required this.enableEnhancedLiveness,
    required this.consentStep,
    required this.instructionsStep,
    required this.previewStep,
    required this.userId,
    required this.partnerId,
    required this.partnerName,
    required this.callbackUrl,
  });

  /// The product this run submits.
  final UseSmileIDSampleProduct product;

  /// Which presentation hosts the flow.
  final UseSmileIDSampleFlowRoute route;

  /// What the user-details form collected.
  final UseSmileIDSampleUserDetails userDetails;

  /// What the ID form collected.
  final UseSmileIDSampleIdDetails idDetails;

  /// The flow scenario in effect.
  final UseSmileIDSampleScenario scenario;

  /// The theme scenario in effect.
  final UseSmileIDSampleThemeScenario theme;

  /// Whether the run submits against sandbox.
  final bool sandbox;

  /// Whether an operator may capture for the applicant.
  final bool allowAgentMode;

  /// Whether the head-turn challenge runs.
  final bool enableEnhancedLiveness;

  /// Whether the SDK's consent step is composed in.
  final bool consentStep;

  /// Whether the instructions step is composed in.
  final bool instructionsStep;

  /// Whether a preview follows each capture.
  final bool previewStep;

  /// The id this run submits under.
  final String userId;

  /// The active profile's id, which the SDK submits as the partner.
  final String partnerId;

  /// The active profile's organisation, which the consent screen names.
  final String partnerName;

  /// The active profile's webhook URL; empty means their portal default.
  final String callbackUrl;

  /// Where the run submitted, which is the only thing that publishes it.
  UseSmileIDSampleEnvironment get environment => sandbox
      ? UseSmileIDSampleEnvironment.sandbox
      : UseSmileIDSampleEnvironment.production;
}
