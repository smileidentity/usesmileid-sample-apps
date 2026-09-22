import 'package:usesmileid/usesmileid.dart';

import 'use_smileid_sample_flow_builder_config.dart';
import 'use_smileid_sample_flow_launch_snapshot.dart';

/// What the gate decided, and so where the journey goes instead of the SDK.
sealed class UseSmileIDSampleFlowPreflight {
  const UseSmileIDSampleFlowPreflight();
}

/// Nothing stands between this snapshot and the SDK.
class UseSmileIDSampleFlowReady extends UseSmileIDSampleFlowPreflight {
  /// No fields: a ready gate has nothing to report.
  const UseSmileIDSampleFlowReady();
}

/// The forms can resolve it.
class UseSmileIDSampleFlowNeedsDetails extends UseSmileIDSampleFlowPreflight {
  /// [issues] is what the SDK's own validators reported.
  const UseSmileIDSampleFlowNeedsDetails(this.issues);

  /// What the payload validators rejected.
  final List<UseSmileIDValidationException> issues;
}

/// No form can resolve it, and it must still never reach the SDK.
class UseSmileIDSampleFlowMisconfigured extends UseSmileIDSampleFlowPreflight {
  /// [issues] is what `validate()` reported about the builder itself.
  const UseSmileIDSampleFlowMisconfigured(this.issues);

  /// What the builder validator rejected.
  final List<UseSmileIDValidationException> issues;
}

/// The entry gate: the SDK's non-throwing pre-flight plus its per-payload validators.
UseSmileIDSampleFlowPreflight useSmileIDSamplePreflight(
  UseSmileIDSampleFlowLaunchSnapshot snapshot,
) {
  final UseSmileIDFlowBuilder builder = UseSmileIDFlowBuilder();
  useSmileIDSampleApplying(builder, snapshot);

  // Payloads before the builder's verdict: a form can fix what was typed, not how this built it.
  final List<ValidationState> payloadChecks = <ValidationState>[
    if (builder.userDetails case final UserDetails details)
      builder.validateUserDetails(details),
    if (builder.biometricKYCParams case final BiometricKYCParams params)
      builder.validateBiometricKYCParams(params),
    if (builder.enhancedKYCParams case final EnhancedKYCParams params)
      builder.validateEnhancedKYCParams(params),
    if (builder.documentVerificationParams
        case final DocumentVerificationParams params)
      builder.validateDocumentVerificationParams(params),
    if (builder.enhancedDocumentVerificationParams
        case final EnhancedDocumentVerificationParams params)
      builder.validateEnhancedDocumentVerificationParams(params),
  ];
  final List<UseSmileIDValidationException> payloadIssues =
      <UseSmileIDValidationException>[
        for (final ValidationState state in payloadChecks)
          if (state case final ValidationStateInvalid invalid)
            ...invalid.issues,
      ];
  if (payloadIssues.isNotEmpty) {
    return UseSmileIDSampleFlowNeedsDetails(payloadIssues);
  }
  return switch (builder.validate()) {
    ValidationStateValid() => const UseSmileIDSampleFlowReady(),
    final ValidationStateInvalid invalid => UseSmileIDSampleFlowMisconfigured(
      invalid.issues,
    ),
  };
}
