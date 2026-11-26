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
}

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
