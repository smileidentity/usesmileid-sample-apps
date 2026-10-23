import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/navigation/use_smileid_sample_njia.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';

import 'support/use_smileid_sample_test_njia.dart';

/// Back from a screen a link opened, by its own back and by the system's: njia opens a link with the stack a user would have had, so back lands on the step under it.
void main() {
  for (final (String at, UseSmileIDSampleStep lands)
      in <(String, UseSmileIDSampleStep)>[
        ('/profiles', UseSmileIDSampleStep.settings),
        ('/profiles/p-1', UseSmileIDSampleStep.profiles),
        ('/flow/biometricKyc/details', UseSmileIDSampleStep.products),
        // The shortest stack a user could have had: a product tap reaches the ID form when the token binds the user's details.
        ('/flow/biometricKyc/id-details', UseSmileIDSampleStep.products),
      ]) {
    Future<void> pump(WidgetTester tester) async {
      final RouterConfig<Uri> router = useSmileIDSampleTestRouter(at);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...useSmileIDSampleTestNjia(),
            useSmileIDSampleLaunchArgsProvider.overrideWithValue(
              const UseSmileIDSampleLaunchArgs(seedProfiles: true),
            ),
          ],
          child: MaterialApp.router(
            theme: UseSmileIDSampleTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('back from $at lands on $lands', (WidgetTester tester) async {
      await pump(tester);

      // The screen's own back, invoked as the app bar invokes it.
      tester
          .widget<UseSmileIDSampleTopAppBar>(
            find.byType(UseSmileIDSampleTopAppBar),
          )
          .onBack();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'back threw from $at');
      expect(useSmileIDSampleTestTop(tester), lands);
    });

    testWidgets('system back from $at lands on $lands', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      // The engine's message for the hardware button, so the whole path from the binding down runs.
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
          const MethodCall('popRoute'),
        ),
        (ByteData? _) {},
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'system back threw from $at',
      );
      expect(useSmileIDSampleTestTop(tester), lands);
    });
  }
}
