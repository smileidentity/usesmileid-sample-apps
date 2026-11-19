import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_sample_flutter/src/screens/use_smileid_sample_settings_sheets.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_shell_extension.dart';

/// The step closes exactly once for a sheet it can't draw, and never for one it can.
void main() {
  Future<void> mount(
    WidgetTester tester,
    String sheetId,
    VoidCallback onDismiss,
  ) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        useSmileIDSampleShellExtensionProvider.overrideWithValue(_Timings()),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: UseSmileIDSampleDebugSheetStep(
          sheetId: sheetId,
          onDismiss: onDismiss,
        ),
      ),
    ),
  );

  testWidgets('draws a sheet its extension draws and stays open', (
    WidgetTester tester,
  ) async {
    int closes = 0;
    await mount(tester, 'captureTimings', () => closes++);
    await tester.pump();
    expect(find.text('sheet captureTimings'), findsOne);
    expect(closes, 0);
  });

  testWidgets(
    'closes once for an id the extension does not draw, even after a rebuild',
    (WidgetTester tester) async {
      int closes = 0;
      await mount(tester, 'unknown', () => closes++);
      await mount(tester, 'unknown', () => closes++);
      await tester.pump();
      expect(closes, 1);
      expect(find.textContaining('sheet'), findsNothing);
    },
  );
}

/// An extension that draws one debug sheet.
class _Timings extends UseSmileIDSampleShellExtension {
  @override
  bool hasDebugSheet(String sheetId) => sheetId == 'captureTimings';

  @override
  Widget debugSheet(String sheetId, VoidCallback onDismiss) =>
      Text('sheet $sheetId');
}
