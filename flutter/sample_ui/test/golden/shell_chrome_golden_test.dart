import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'golden_harness.dart';

/// The caller's picture: two halves each agreeing with themselves while disagreeing with the caller is how a defect ships.
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

/// The shell's own layout, slot for slot; [page] builds in the body, where the bar's height reaches.
Widget _shell(UseSmileIDSampleNavItem selected, WidgetBuilder page) => Scaffold(
  // Transparent, so the host's page colour still reaches the capture.
  backgroundColor: Colors.transparent,
  extendBody: true,
  bottomNavigationBar: UseSmileIDSampleNavBar(
    selected: selected,
    onSelect: _ignoreNavItem,
    onTokenTap: () {},
  ),
  body: Builder(builder: page),
);

Widget _overProducts() => _shell(
  UseSmileIDSampleNavItem.products,
  (BuildContext context) => UseSmileIDSampleProductsScreen(
    state: UseSmileIDSampleProductsState(
      initials: 'KB',
      avatarColor: avatarColorForProfile(0),
    ),
    onProductTap: _ignoreProduct,
    onProfileTap: () {},
    onScanTap: () {},
    bottomInset: useSmileIDSampleNavBarClearance(context),
  ),
);

Widget _overVerifications() => _shell(
  UseSmileIDSampleNavItem.verifications,
  (BuildContext context) => ListView(
    padding: EdgeInsets.only(bottom: useSmileIDSampleNavBarClearance(context)),
    children: const <Widget>[
      UseSmileIDSampleEmptyState(
        text: 'No verifications yet',
        supportingText: 'Start a product above and the job lands here.',
      ),
    ],
  ),
);

Widget _overSettings() => _shell(
  UseSmileIDSampleNavItem.settings,
  (BuildContext context) => UseSmileIDSampleSettingsScreen(
    state: const UseSmileIDSampleSettingsState(
      settings: UseSmileIDSampleSettings(),
      organisation: 'No profile yet',
      initials: '',
      versionLabel: 'Smile ID · 1.0.0',
    ),
    onSettingChanged: _ignoreSetting,
    onProfileTap: () {},
    onNavRowTap: _ignoreNavRow,
    onSignOut: () {},
    bottomInset: useSmileIDSampleNavBarClearance(context),
  ),
);

void _ignoreNavItem(UseSmileIDSampleNavItem item) {}

void _ignoreProduct(UseSmileIDSampleProduct product) {}

void _ignoreSetting(UseSmileIDSampleSetting setting, bool enabled) {}

void _ignoreNavRow(UseSmileIDSampleNavRow row) {}
