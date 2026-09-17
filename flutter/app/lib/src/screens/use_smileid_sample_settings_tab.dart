import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../use_smileid_sample_routes.dart';
import '../use_smileid_sample_version.dart';

/// The settings tab, whose six switches survive a restart.
///
/// Nothing here holds the values: the notifier writes through the repository and takes back what
/// was stored, which is how the capture mutex reaches both persistence paths rather than one.
class UseSmileIDSampleSettingsTab extends ConsumerWidget {
  /// Takes nothing; the switches and the profile both come from their stores.
  const UseSmileIDSampleSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    return UseSmileIDSampleSettingsScreen(
      state: UseSmileIDSampleSettingsState(
        settings: ref.watch(useSmileIDSampleSettingsProvider),
        organisation: profiles.active.organisation,
        initials: profiles.active.initials,
        versionLabel: useSmileIDSampleVersionLabel,
        avatarColor: avatarColorForProfile(profiles.activeIndex),
      ),
      onSettingChanged: (UseSmileIDSampleSetting setting, bool enabled) => ref
          .read(useSmileIDSampleSettingsProvider.notifier)
          .setSetting(setting, enabled),
      // The LIST, not the active profile's own page: the twin's row is a way into every profile.
      onProfileTap: () => context.go(UseSmileIDSampleRoutes.profiles),
      onNavRowTap: (UseSmileIDSampleNavRow row) {},
      onSignOut: () {},
      bottomInset: useSmileIDSampleNavBarClearance(context),
    );
  }
}
