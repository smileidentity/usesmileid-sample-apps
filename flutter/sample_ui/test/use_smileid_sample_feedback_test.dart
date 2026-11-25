import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

void main() {
  test('a held card shrinks to 0.97', () {
    expect(
      useSmileIDSamplePressScale(
        pressed: true,
        enabled: true,
        reduceMotion: false,
      ),
      0.97,
    );
  });

  test('a card at rest keeps its size', () {
    expect(
      useSmileIDSamplePressScale(
        pressed: false,
        enabled: true,
        reduceMotion: false,
      ),
      1,
    );
  });

  test('a disabled card does not shrink', () {
    expect(
      useSmileIDSamplePressScale(
        pressed: true,
        enabled: false,
        reduceMotion: false,
      ),
      1,
    );
  });

  test('a card does not shrink when the platform asks for reduced motion', () {
    expect(
      useSmileIDSamplePressScale(
        pressed: true,
        enabled: true,
        reduceMotion: true,
      ),
      1,
    );
  });

  testWidgets('a card scales down while it is held', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        UseSmileIDSampleProductCard(
          title: 'Document',
          family: 'Verification',
          hue: productHue(UseSmileIDSampleProduct.documentVerification),
          onTap: () {},
        ),
      ),
    );

    final TestGesture press = await tester.startGesture(
      tester.getCenter(find.byType(UseSmileIDSampleProductCard)),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.97,
    );

    await press.up();
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('picking another chip ticks once', (WidgetTester tester) async {
    final List<Object?> ticks = _recordHaptics(tester);
    await tester.pumpWidget(
      _host(
        UseSmileIDSampleFilterChip(
          label: 'Failed',
          count: 2,
          selected: false,
          onTap: () {},
        ),
      ),
    );

    await tester.tap(find.byType(UseSmileIDSampleFilterChip));

    expect(ticks, <Object?>['HapticFeedbackType.selectionClick']);
  });

  testWidgets('tapping the chip already picked does not tick', (
    WidgetTester tester,
  ) async {
    final List<Object?> ticks = _recordHaptics(tester);
    await tester.pumpWidget(
      _host(
        UseSmileIDSampleFilterChip(
          label: 'All',
          count: 4,
          selected: true,
          onTap: () {},
        ),
      ),
    );

    await tester.tap(find.byType(UseSmileIDSampleFilterChip));

    expect(ticks, isEmpty);
  });

  testWidgets('moving to another tab ticks once', (WidgetTester tester) async {
    final List<Object?> ticks = _recordHaptics(tester);
    await tester.pumpWidget(_host(_navBar()));

    await tester.tap(
      find.bySemanticsIdentifier(UseSmileIDSampleTestIds.navVerifications),
    );

    expect(ticks, <Object?>['HapticFeedbackType.selectionClick']);
  });

  testWidgets('tapping the tab already open does not tick', (
    WidgetTester tester,
  ) async {
    final List<Object?> ticks = _recordHaptics(tester);
    await tester.pumpWidget(_host(_navBar()));

    await tester.tap(
      find.bySemanticsIdentifier(UseSmileIDSampleTestIds.navProducts),
    );

    expect(ticks, isEmpty);
  });

  testWidgets(
    'a switch ticks exactly once per toggle',
    (WidgetTester tester) async {
      final List<Object?> ticks = _recordHaptics(tester);
      await tester.pumpWidget(
        _host(UseSmileIDSampleSwitch(value: false, onChanged: (_) {})),
      );

      await tester.tap(find.byType(UseSmileIDSampleSwitch));
      await tester.pumpAndSettle();

      expect(ticks, hasLength(1));
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('a disabled switch does not tick', (WidgetTester tester) async {
    final List<Object?> ticks = _recordHaptics(tester);
    await tester.pumpWidget(
      _host(
        UseSmileIDSampleSwitch(value: false, onChanged: (_) {}, enabled: false),
      ),
    );

    await tester.tap(find.byType(UseSmileIDSampleSwitch));
    await tester.pumpAndSettle();

    expect(ticks, isEmpty);
  });
}

List<Object?> _recordHaptics(WidgetTester tester) {
  final List<Object?> ticks = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') ticks.add(call.arguments);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return ticks;
}

Widget _navBar() => UseSmileIDSampleNavBar(
  selected: UseSmileIDSampleNavItem.products,
  onSelect: (_) {},
  onTokenTap: () {},
);

Widget _host(Widget child) => MaterialApp(
  theme: UseSmileIDSampleTheme.light(),
  home: UseSmileIDSampleStringsScope(
    language: UseSmileIDSampleLanguage.en,
    deviceLanguages: const <String>[],
    child: Material(
      child: Center(child: SizedBox(width: 393, child: child)),
    ),
  ),
);
