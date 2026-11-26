import 'package:flutter/material.dart';
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

  testWidgets('a chip eases into its picked colour instead of snapping', (
    WidgetTester tester,
  ) async {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      await _contextOf(tester),
    );
    await tester.pumpWidget(_host(_chip(selected: false)));
    await tester.pumpWidget(_host(_chip(selected: true)));
    await tester.pump(const Duration(milliseconds: 100));

    final Color midway = _pillColor(tester);
    expect(midway, isNot(colors.primary));
    expect(midway, isNot(colors.filterChip.background));

    await tester.pumpAndSettle();
    expect(_pillColor(tester), colors.primary);
  });

  testWidgets('a chip snaps when the platform asks for reduced motion', (
    WidgetTester tester,
  ) async {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      await _contextOf(tester),
    );
    await tester.pumpWidget(_host(_chip(selected: false), reduceMotion: true));
    await tester.pumpWidget(_host(_chip(selected: true), reduceMotion: true));
    await tester.pump();

    expect(_pillColor(tester), colors.primary);
  });

  testWidgets('a tab eases into its picked tint instead of snapping', (
    WidgetTester tester,
  ) async {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      await _contextOf(tester),
    );
    await tester.pumpWidget(_host(_navBar(UseSmileIDSampleNavItem.products)));
    await tester.pumpWidget(
      _host(_navBar(UseSmileIDSampleNavItem.verifications)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final Color midway = _tabLabelColor(tester);
    expect(midway, isNot(colors.primary));
    expect(midway, isNot(colors.foreground));

    await tester.pumpAndSettle();
    expect(_tabLabelColor(tester), colors.primary);
  });
}

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: UseSmileIDSampleTheme.light(),
  builder: (BuildContext context, Widget? app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: app!,
  ),
  home: UseSmileIDSampleStringsScope(
    language: UseSmileIDSampleLanguage.en,
    deviceLanguages: const <String>[],
    child: Material(
      child: Center(child: SizedBox(width: 393, child: child)),
    ),
  ),
);

Future<BuildContext> _contextOf(WidgetTester tester) async {
  await tester.pumpWidget(_host(const SizedBox()));
  return tester.element(find.byType(SizedBox).last);
}

Widget _chip({required bool selected}) => UseSmileIDSampleFilterChip(
  label: 'Clear',
  count: 2,
  selected: selected,
  onTap: () {},
);

Widget _navBar(UseSmileIDSampleNavItem selected) => UseSmileIDSampleNavBar(
  selected: selected,
  onSelect: (_) {},
  onTokenTap: () {},
);

Color _pillColor(WidgetTester tester) => tester
    .widget<Material>(
      find.descendant(
        of: find.byType(UseSmileIDSampleFilterChip),
        matching: find.byType(Material),
      ),
    )
    .color!;

Color _tabLabelColor(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.bySemanticsIdentifier(
          UseSmileIDSampleTestIds.navVerifications,
        ),
        matching: find.byType(Text),
      ),
    )
    .style!
    .color!;
