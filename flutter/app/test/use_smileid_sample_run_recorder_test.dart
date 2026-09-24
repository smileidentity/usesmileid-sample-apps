import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_launch_snapshot.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_flow_result_provider.dart';

/// The run's start and its first delivery can land in either order; the count must not care.
void main() {
  const UseSmileIDSampleFlowLaunchSnapshot snapshot =
      UseSmileIDSampleFlowLaunchSnapshot(
        product: UseSmileIDSampleProduct.smartSelfieEnrollment,
        route: UseSmileIDSampleFlowRoute.fullscreen,
        userDetails: UseSmileIDSampleUserDetails(),
        idDetails: UseSmileIDSampleIdDetails(),
        scenario: UseSmileIDSampleScenario.normal,
        theme: UseSmileIDSampleThemeScenario.brandDefault,
        sandbox: false,
        allowAgentMode: false,
        enableEnhancedLiveness: true,
        consentStep: true,
        instructionsStep: true,
        previewStep: true,
        userId: 'user_1',
        partnerId: 'profile-1',
        partnerName: 'Kobo Bank',
        callbackUrl: '',
      );

  late ProviderContainer container;
  late UseSmileIDSampleRunRecorder run;

  setUp(() {
    container = ProviderContainer();
    run = UseSmileIDSampleRunRecorder(
      container.read(useSmileIDSampleFlowResultProvider.notifier),
      snapshot,
    );
  });

  tearDown(() => container.dispose());

  UseSmileIDSampleResult result() =>
      container.read(useSmileIDSampleFlowResultProvider);

  test(
    'a delivery on the SDK first frame survives the mount starting the run',
    () {
      run.deliver(UseSmileIDSampleFlowStatus.failed, error: 'no camera');
      run.ensureStarted();
      expect(result().resultCallbackCount, 1);
      expect(result().jobStatus, UseSmileIDSampleFlowStatus.failed);
      expect(result().environment, UseSmileIDSampleEnvironment.production);
    },
  );

  test('the mount starting first leaves one delivery counted once', () {
    run.ensureStarted();
    run.deliver(UseSmileIDSampleFlowStatus.cancelled);
    run.ensureStarted();
    expect(result().resultCallbackCount, 1);
    expect(result().jobStatus, UseSmileIDSampleFlowStatus.cancelled);
  });
}
