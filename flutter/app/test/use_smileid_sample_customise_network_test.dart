import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_builder_config.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_launch_snapshot.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_shell_extension.dart';

import 'support/use_smileid_sample_test_session.dart';

class _Recording extends UseSmileIDSampleShellExtension {
  final List<UseSmileIDSampleProduct> customised = <UseSmileIDSampleProduct>[];

  @override
  void customiseNetwork(
    UseSmileIDNetworkBuilder network,
    UseSmileIDSampleProduct product,
  ) => customised.add(product);
}

void main() {
  test(
    'the extension customises the network the shell configured for the product',
    () {
      final _Recording extension = _Recording();
      useSmileIDSampleApplying(
        UseSmileIDFlowBuilder(),
        UseSmileIDSampleFlowLaunchSnapshot(
          product: UseSmileIDSampleProduct.smartSelfieEnrollment,
          route: UseSmileIDSampleFlowRoute.fullscreen,
          userDetails: const UseSmileIDSampleUserDetails(
            firstName: 'Ada',
            lastName: 'Okafor',
            email: 'ada@example.com',
          ),
          idDetails: const UseSmileIDSampleIdDetails(),
          scenario: UseSmileIDSampleScenario.normal,
          theme: UseSmileIDSampleThemeScenario.brandDefault,
          sandbox: true,
          allowAgentMode: false,
          enableEnhancedLiveness: true,
          consentStep: true,
          instructionsStep: true,
          previewStep: true,
          userId: 'user_1',
          partnerId: 'profile-1',
          partnerName: 'Kobo Bank',
          callbackUrl: '',
          session: useSmileIDSampleTestSession(),
        ),
        extension: extension,
      );
      expect(extension.customised, <UseSmileIDSampleProduct>[
        UseSmileIDSampleProduct.smartSelfieEnrollment,
      ]);
    },
  );
}
