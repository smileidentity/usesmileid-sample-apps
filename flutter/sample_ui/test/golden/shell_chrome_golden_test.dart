import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// What the shell actually draws: the bar floating over a tab root, with the room it asks for.
///
/// The screens have their own pictures without it, and a component's picture agreeing with its
/// component while both disagree with the only caller is how a defect ships. This is the caller's
/// picture, so the composition is pinned rather than inferred from two halves.
void main() {
  setUpAll(loadSampleFonts);

  testWidgets('shell chrome over products', (WidgetTester tester) async {
    await _chromeGoldens(tester, 'shell_chrome_products', _overProducts);
  });

  testWidgets('shell chrome over verifications', (WidgetTester tester) async {
    await _chromeGoldens(
      tester,
      'shell_chrome_verifications',
      _overVerifications,
    );
  });

  testWidgets('shell chrome over settings', (WidgetTester tester) async {
    await _chromeGoldens(tester, 'shell_chrome_settings', _overSettings);
  });
}

Future<void> _chromeGoldens(
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

/// The shell's own layout: the page, then the bar over it, anchored to the bottom.
Widget _shell(UseSmileIDSampleNavItem selected, Widget page) => Stack(
  children: <Widget>[
    page,
    Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: UseSmileIDSampleNavBar(
        selected: selected,
        onSelect: _ignoreNavItem,
        onTokenTap: () {},
      ),
    ),
  ],
);

Widget _overProducts() => Builder(
  builder: (BuildContext context) => _shell(
    UseSmileIDSampleNavItem.products,
    UseSmileIDSampleProductsScreen(
      state: UseSmileIDSampleProductsState(
        initials: 'KB',
        avatarColor: avatarColorForProfile(0),
      ),
      onProductTap: _ignoreProduct,
      onProfileTap: () {},
      onScanTap: () {},
      bottomInset: useSmileIDSampleNavBarClearance(context),
    ),
  ),
);

Widget _overVerifications() => _shell(
  UseSmileIDSampleNavItem.verifications,
  const Center(
    child: UseSmileIDSampleEmptyState(
      text: 'No verifications yet',
      supportingText: 'Run a product to see it here',
    ),
  ),
);

Widget _overSettings() => Builder(
  builder: (BuildContext context) => _shell(
    UseSmileIDSampleNavItem.settings,
    UseSmileIDSampleSettingsScreen(
      state: const UseSmileIDSampleSettingsState(
        settings: UseSmileIDSampleSettings(),
        organisation: 'Default profile',
        initials: 'DP',
        versionLabel: 'Smile ID · 1.0.0',
      ),
      onSettingChanged: _ignoreSetting,
      onProfileTap: () {},
      onNavRowTap: _ignoreNavRow,
      onSignOut: () {},
      bottomInset: useSmileIDSampleNavBarClearance(context),
    ),
  ),
);

void _ignoreNavItem(UseSmileIDSampleNavItem item) {}

void _ignoreProduct(UseSmileIDSampleProduct product) {}

void _ignoreSetting(UseSmileIDSampleSetting setting, bool enabled) {}

void _ignoreNavRow(UseSmileIDSampleNavRow row) {}
