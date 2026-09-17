import 'package:flutter/widgets.dart';
import 'package:sample_ui/sample_ui.dart';

import '../use_smileid_sample_starter_profile.dart';

/// The products tab: the grid every flow starts from.
///
/// No session and no stored profile yet, which is what a first launch shows on the other two apps.
class UseSmileIDSampleProductsTab extends StatelessWidget {
  /// Takes nothing; the state it shows arrives with the stores.
  const UseSmileIDSampleProductsTab({super.key});

  @override
  Widget build(BuildContext context) => UseSmileIDSampleProductsScreen(
    state: const UseSmileIDSampleProductsState(
      initials: UseSmileIDSampleStarterProfile.initials,
    ),
    onProductTap: (UseSmileIDSampleProduct product) {},
    onProfileTap: () {},
    onScanTap: () {},
    bottomInset: useSmileIDSampleNavBarClearance(context),
  );
}
