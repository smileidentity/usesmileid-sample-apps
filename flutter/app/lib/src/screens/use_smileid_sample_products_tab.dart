import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';

/// The products tab: the grid every flow starts from.
///
/// No session yet, so the header shows the active profile and nothing else; the session card and
/// the scan it leads to arrive with the token store.
class UseSmileIDSampleProductsTab extends ConsumerWidget {
  /// Takes nothing; what it shows comes from the profile store.
  const UseSmileIDSampleProductsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    return UseSmileIDSampleProductsScreen(
      state: UseSmileIDSampleProductsState(
        initials: profiles.active.initials,
        // By POSITION, not by id: the hue is the profile's place in the list, and every screen
        // showing the same profile has to agree on it.
        avatarColor: avatarColorForProfile(profiles.activeIndex),
      ),
      onProductTap: (UseSmileIDSampleProduct product) {},
      onProfileTap: () {},
      onScanTap: () {},
      bottomInset: useSmileIDSampleNavBarClearance(context),
    );
  }
}
