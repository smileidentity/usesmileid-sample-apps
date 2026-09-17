import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// Back on a route ABOVE the shell. Each is entered with `go`, which leaves one page in the match
/// list, so `pop` threw `GoError: There is nothing to pop` on every one of them.
void main() {
  for (final (String at, String lands) in <(String, String)>[
    ('/profiles', '/settings'),
    ('/profiles/profile-1', '/profiles'),
    ('/flow/biometric_kyc/details', '/products'),
    ('/flow/biometric_kyc/id-details', '/flow/biometric_kyc/details'),
  ]) {
    testWidgets('back from $at lands on $lands', (WidgetTester tester) async {
      final GoRouter router = useSmileIDSampleRouter(initialLocation: at);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: UseSmileIDSampleTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

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
  }
}
