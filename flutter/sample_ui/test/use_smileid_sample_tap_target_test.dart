import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// Android pads controls to Compose's 48; iOS keeps the 44 its native twin draws.
void main() {
  Future<BuildContext> pumpOn(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light().copyWith(platform: platform),
        home: const Material(
          child: Column(
            children: <Widget>[UseSmileIDSampleTriggerEmoji(emoji: '🌍')],
          ),
        ),
      ),
    );
    return tester.element(find.byType(UseSmileIDSampleTriggerEmoji));
  }

  testWidgets('the tap target is 48 on Android', (WidgetTester tester) async {
    expect(
      useSmileIDSampleTapTarget(await pumpOn(tester, TargetPlatform.android)),
      48,
    );
  });

  testWidgets('the tap target is 44 on iOS', (WidgetTester tester) async {
    expect(
      useSmileIDSampleTapTarget(await pumpOn(tester, TargetPlatform.iOS)),
      44,
    );
  });

  testWidgets('the trigger emoji fills the icon slot exactly on iOS', (
    WidgetTester tester,
  ) async {
    await pumpOn(tester, TargetPlatform.iOS);
    expect(
      tester.getSize(find.byType(UseSmileIDSampleTriggerEmoji)).height,
      SmileDimens.sizeIconMd,
    );
  });
}
