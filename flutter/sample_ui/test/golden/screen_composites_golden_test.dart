import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// Every state of the screen-specific composites, light and dark, at the shared 393-unit width.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('product card', (WidgetTester tester) async {
    await goldens(tester, 'product_card', _productCards);
  });

  testWidgets('product cards survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _productCards(),
      // Every product word is wider than the card's text column at 2x, so the words break.
      knownOpenWords: _gridOpenWords,
    );
  });

  testWidgets('product grid', (WidgetTester tester) async {
    await goldens(tester, 'product_grid', _productGrid);
  });

  testWidgets('product grid survives max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _productGrid(),
      // Every product word is wider than the card's text column at 2x, so the words break.
      knownOpenWords: _gridOpenWords,
    );
  });

  testWidgets('section header', (WidgetTester tester) async {
    await goldens(tester, 'section_header', _sectionHeaders);
  });

  testWidgets('nav bar', (WidgetTester tester) async {
    await goldens(tester, 'nav_bar', _navBars);
  });

  testWidgets('nav bars survive max text scale', (WidgetTester tester) async {
    await assertSurvivesMaxTextScale(
      tester,
      _navBars(),
      knownOpenWords: _tabOpenWords,
    );
  });

  testWidgets('token ring', (WidgetTester tester) async {
    await goldens(tester, 'token_ring', _tokenRings);
  });

  testWidgets('session card', (WidgetTester tester) async {
    await goldens(tester, 'session_card', _sessionCards);
  });

  testWidgets('session cards survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(tester, _sessionCards());
  });

  testWidgets('floating token button', (WidgetTester tester) async {
    await goldens(tester, 'floating_token_button', _floatingTokenButtons);
  });

  testWidgets('scan glyph', (WidgetTester tester) async {
    await goldens(tester, 'scan_glyph', _scanGlyphs);
  });

  testWidgets('scan sheet', (WidgetTester tester) async {
    await goldens(tester, 'scan_sheet', _scanSheets);
  });

  testWidgets('scan sheets survive max text scale', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      _scanSheets(),
      // A single-line field cannot wrap, so whether its placeholder fits at 2x is a copy question.
      knownEllipsised: const <String>{'Or enter token manually'},
    );
  });

  testWidgets('swipe action', (WidgetTester tester) async {
    await goldens(tester, 'swipe_action', _swipeActions);
  });
}

Widget _stack(List<Widget> children, {double gap = SmileDimens.spacingSm}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < children.length; index++) ...<Widget>[
          if (index > 0) SizedBox(height: gap),
          children[index],
        ],
      ],
    );

Widget _card(UseSmileIDSampleProduct product) => UseSmileIDSampleProductCard(
  title: product.cardTitle,
  family: product.cardFamily,
  hue: productHue(product),
  onTap: () {},
  // The sizes the screen actually passes, so the component baseline is not a fixture nobody draws.
  icon: (Color tint) =>
      UseSmileIDSampleIcon(asset: productIcon(product), tint: tint),
  ghost: (Color tint) => UseSmileIDSampleIcon(
    asset: productIcon(product),
    tint: tint,
    size: SmileDimens.space64 + SmileDimens.space4,
  ),
);

/// The two-up pair the design draws, plus the disabled state and the worst-case label.
Widget _productCards() => _stack(<Widget>[
  IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: _card(UseSmileIDSampleProduct.smartSelfieEnrollment)),
        const SizedBox(width: SmileDimens.spacingSm),
        Expanded(
          child: _card(UseSmileIDSampleProduct.enhancedDocumentVerification),
        ),
      ],
    ),
  ),
  IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: UseSmileIDSampleProductCard(
            title: 'Enhanced',
            family: 'KYC',
            hue: productHue(UseSmileIDSampleProduct.enhancedKyc),
            onTap: () {},
            enabled: false,
          ),
        ),
        const SizedBox(width: SmileDimens.spacingSm),
        const Expanded(child: SizedBox.shrink()),
      ],
    ),
  ),
]);

/// All six, so the odd-count empty cell and every hue are in one picture.
Widget _productGrid() => UseSmileIDSampleProductGrid(
  itemCount: UseSmileIDSampleProduct.values.length,
  itemBuilder: (BuildContext context, int index) =>
      _card(UseSmileIDSampleProduct.values[index]),
);

Widget _sectionHeaders() => _stack(<Widget>[
  for (final UseSmileIDSampleProductSection section
      in UseSmileIDSampleProductSection.values)
    UseSmileIDSampleSectionHeader(text: section.label),
], gap: SmileDimens.spacingXs);

/// With and without a session, so the ring's presence is a visible difference.
Widget _navBars() => _stack(<Widget>[
  UseSmileIDSampleNavBar(
    selected: UseSmileIDSampleNavItem.products,
    onSelect: _ignoreItem,
    onTokenTap: () {},
  ),
  UseSmileIDSampleNavBar(
    selected: UseSmileIDSampleNavItem.verifications,
    onSelect: _ignoreItem,
    onTokenTap: () {},
    sessionProgress: 0.62,
  ),
]);

/// Four phases of one countdown, which is what makes a sweep-direction error visible.
Widget _tokenRings() => Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: const <Widget>[
    UseSmileIDSampleTokenRing(progress: 1),
    UseSmileIDSampleTokenRing(progress: 0.62),
    UseSmileIDSampleTokenRing(progress: 0.15),
    UseSmileIDSampleTokenRing(progress: 0),
  ],
);

Widget _sessionCards() => _stack(<Widget>[
  const UseSmileIDSampleSessionCard(sessionId: '7d2f01aa', remaining: '12:47'),
  UseSmileIDSampleSessionEndedBanner(onScan: () {}),
]);

Widget _floatingTokenButtons() => Align(
  alignment: Alignment.centerLeft,
  child: UseSmileIDSampleFloatingTokenButton(onTap: () {}),
);

Widget _scanGlyphs() => const Align(child: UseSmileIDSampleScanGlyph());

Widget _scanSheets() => _stack(<Widget>[
  UseSmileIDSampleScanSheet(
    state: const UseSmileIDSampleScanSheetState(),
    onTokenChanged: _ignore,
    onPaste: () {},
    onLink: () {},
    onExpandToggle: () {},
    onSpanSelect: (_) {},
    onEnvironmentSelect: (_) {},
    onBindingsChanged: (_) {},
    onSimulate: () {},
  ),
  UseSmileIDSampleScanSheet(
    state: const UseSmileIDSampleScanSheetState(
      token: 'eyJhbGciOi',
      rejection: 'That token is not a session',
    ),
    onTokenChanged: _ignore,
    onPaste: () {},
    onLink: () {},
    onExpandToggle: () {},
    onSpanSelect: (_) {},
    onEnvironmentSelect: (_) {},
    onBindingsChanged: (_) {},
    onSimulate: () {},
  ),
  // The mint controls open, with a non-default choice in each row so selection reads.
  UseSmileIDSampleScanSheet(
    state: const UseSmileIDSampleScanSheetState(
      span: UseSmileIDSampleSimulatedSpan.eightHours,
      environment: UseSmileIDSampleEnvironment.production,
      bindings: UseSmileIDSampleSimulatedBindings(consent: true),
      expanded: true,
    ),
    onTokenChanged: _ignore,
    onPaste: () {},
    onLink: () {},
    onExpandToggle: () {},
    onSpanSelect: (_) {},
    onEnvironmentSelect: (_) {},
    onBindingsChanged: (_) {},
    onSimulate: () {},
  ),
]);

/// The revealed action, which is the only part of the gesture the design fixes.
Widget _swipeActions() => Builder(
  builder: (BuildContext context) => ColoredBox(
    color: UseSmileIDSampleTheme.colorsOf(context).surface,
    child: SizedBox(
      height: SmileDimens.space64,
      child: UseSmileIDSampleSwipeAction(
        dismissKey: const ValueKey<String>('golden'),
        onRemove: () {},
        child: const SizedBox.shrink(),
      ),
    ),
  ),
);

void _ignore(String value) {}

void _ignoreItem(UseSmileIDSampleNavItem item) {}

/// Each tab label is wider than a third of the pill at 2x — `port-adversarial-review.md` C5.
const Set<String> _tabOpenWords = <String>{
  'Products',
  'Verifications',
  'Settings',
};

/// The words `ui-work-plan.md` §5 item 3a records as breaking at 2x in the design's own grid.
const Set<String> _gridOpenWords = <String>{
  'Registration',
  'Document',
  'Enhanced',
  'Biometric',
  'Verification',
  'SmartSelfie\u2122',
};
