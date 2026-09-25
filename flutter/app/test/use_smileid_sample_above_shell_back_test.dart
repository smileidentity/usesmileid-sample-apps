import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// Back on a route ABOVE the shell. Each is entered with `go`, which leaves one page in the root
/// stack: `pop` threw `GoError: There is nothing to pop` on three of them (the profile editor is a
/// child route with a page under it), and a system back nothing handles leaves the app instead.
void main() {
  for (final (String at, String lands) in <(String, String)>[
    ('/profiles', '/settings'),
    ('/profiles/p-1', '/profiles'),
    ('/flow/biometric_kyc/details', '/products'),
    ('/flow/biometric_kyc/id-details', '/flow/biometric_kyc/details'),
  ]) {
    Future<GoRouter> pump(WidgetTester tester) async {
      final GoRouter router = useSmileIDSampleRouter(initialLocation: at);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
      return router;
    }

    testWidgets('back from $at lands on $lands', (WidgetTester tester) async {
      final GoRouter router = await pump(tester);

      // The screen's own back, invoked as the app bar invokes it.
      tester
          .widget<UseSmileIDSampleTopAppBar>(
            find.byType(UseSmileIDSampleTopAppBar),
          )
          .onBack();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'back threw from $at');
      expect(router.routerDelegate.currentConfiguration.uri.toString(), lands);
    });

    testWidgets('system back from $at lands on $lands', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pump(tester);

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
      expect(router.routerDelegate.currentConfiguration.uri.toString(), lands);
    });
  }
}
