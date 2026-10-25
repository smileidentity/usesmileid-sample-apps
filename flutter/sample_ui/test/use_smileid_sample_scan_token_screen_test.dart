import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The scan screen's own failure paths, which no golden can reach.
void main() {
  testWidgets('a clipboard that throws reads as an empty one', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: Scaffold(
          body: UseSmileIDSampleScanTokenScreen(
            onBack: () {},
            onLink: (_) {},
            onSimulate: (_, _, _) {},
            onPaste: () async => throw StateError('clipboard unavailable'),
          ),
        ),
      ),
    );
    await tester.tap(
      find.bySemanticsIdentifier(UseSmileIDSampleTestIds.tokenPaste),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('The clipboard holds no text to paste.'), findsOne);
  });

  for (final bool camera in <bool>[false, true]) {
    testWidgets(
      camera
          ? 'the camera copy fits above the keyboard'
          : 'the placeholder copy fits above the keyboard',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 336);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: UseSmileIDSampleTheme.light(),
            home: Scaffold(
              body: UseSmileIDSampleScanTokenScreen(
                onBack: () {},
                onLink: (_) {},
                onSimulate: (_, _, _) {},
                onPaste: () async => null,
                viewfinder: camera
                    ? (
                        BuildContext context, {
                        required bool enabled,
                        required ValueChanged<String> onCandidate,
                      }) => const ColoredBox(color: Colors.black)
                    : null,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final bool accepts in <bool>[false, true]) {
    testWidgets(
      accepts
          ? 'a settled screen simulates on a tap'
          : 'a screen still arriving ignores a tap on Simulate',
      (WidgetTester tester) async {
        int simulated = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: UseSmileIDSampleTheme.light(),
            home: Scaffold(
              body: UseSmileIDSampleScanTokenScreen(
                onBack: () {},
                onLink: (_) {},
                onSimulate: (_, _, _) => simulated++,
                onPaste: () async => null,
                acceptsTaps: accepts,
              ),
            ),
          ),
        );
        await tester.tap(
          find.bySemanticsIdentifier(UseSmileIDSampleTestIds.tokenSimulate),
        );
        await tester.pump();

        expect(simulated, accepts ? 1 : 0);
      },
    );
  }
}
