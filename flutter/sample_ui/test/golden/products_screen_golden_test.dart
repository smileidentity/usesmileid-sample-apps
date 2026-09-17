import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The four reachable states `spec/screens.json` lists for products, light and dark.
///
/// `supersededListLayout` is not among them on purpose: the spec keeps that node only so nobody
/// re-implements it by accident. Nor is `production` — no production state is reachable from the
/// app now that the token's own claim decides the environment.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('products default', (WidgetTester tester) async {
    await _screenGoldens(tester, 'screen_products', _products);
  });

  testWidgets('products survives max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(
      tester,
      _products(),
      ownsScrolling: true,
      hostHeight: goldenScreenHeight * 2,
      // Every product word is wider than the card's text column at 2x — `ui-work-plan.md` §5
      // item 3a, an open design question this port must not answer.
      knownOpenWords: _gridOpenWords,
    );
  });

  testWidgets('products token linked', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_products_token_linked',
      () => _products(sessionId: '7d2f01aa', sessionRemaining: '5:00'),
    );
  });

  /// The same card at 1:40, which is the state the design draws on the older frame.
  testWidgets('products token linked late', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_products_token_linked_late',
      () => _products(sessionId: '7d2f01aa', sessionRemaining: '1:40'),
    );
  });

  testWidgets('products token expired', (WidgetTester tester) async {
    await _screenGoldens(
      tester,
      'screen_products_token_expired',
      () => _products(sessionEnded: true),
    );
  });
}

Future<void> _screenGoldens(
  WidgetTester tester,
  String name,
  Widget Function() build,
) => goldens(
  tester,
  name,
  build,
  hostHeight: goldenScreenHeight,
  fillsHost: true,
);

Widget _products({
  String? sessionId,
  String? sessionRemaining,
  bool sessionEnded = false,
}) => UseSmileIDSampleProductsScreen(
  state: UseSmileIDSampleProductsState(
    initials: 'KB',
    avatarColor: avatarColorForProfile(0),
    sessionId: sessionId,
    sessionRemaining: sessionRemaining,
    sessionEnded: sessionEnded,
  ),
  onProductTap: _ignoreProduct,
  onProfileTap: () {},
  onScanTap: () {},
);

void _ignoreProduct(UseSmileIDSampleProduct product) {}

/// The words `ui-work-plan.md` §5 item 3a records as breaking at 2x in the design's own grid.
const Set<String> _gridOpenWords = <String>{
  'Registration',
  'Document',
  'Enhanced',
  'Biometric',
  'Verification',
  'SmartSelfie™',
};
