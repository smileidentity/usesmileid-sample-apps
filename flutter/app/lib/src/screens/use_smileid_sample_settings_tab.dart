import 'package:flutter/widgets.dart';
import 'package:sample_ui/sample_ui.dart';

import '../use_smileid_sample_starter_profile.dart';
import '../use_smileid_sample_version.dart';

/// The settings tab.
///
/// The six switches live here for the life of the process; the repository that makes them survive a
/// restart is the next branch, and the mutex they share already lives on the state object.
class UseSmileIDSampleSettingsTab extends StatefulWidget {
  /// Takes nothing; the switches it holds are replaced by the stored settings.
  const UseSmileIDSampleSettingsTab({super.key});

  @override
  State<UseSmileIDSampleSettingsTab> createState() =>
      _UseSmileIDSampleSettingsTabState();
}

class _UseSmileIDSampleSettingsTabState
    extends State<UseSmileIDSampleSettingsTab> {
  UseSmileIDSampleSettings _settings = const UseSmileIDSampleSettings();

  @override
  Widget build(BuildContext context) => UseSmileIDSampleSettingsScreen(
    state: UseSmileIDSampleSettingsState(
      settings: _settings,
      organisation: UseSmileIDSampleStarterProfile.organisation,
      initials: UseSmileIDSampleStarterProfile.initials,
      versionLabel: useSmileIDSampleVersionLabel,
    ),
    onSettingChanged: (UseSmileIDSampleSetting setting, bool enabled) =>
        setState(() => _settings = _settings.withSetting(setting, enabled)),
    onProfileTap: () {},
    onNavRowTap: (UseSmileIDSampleNavRow row) {},
    onSignOut: () {},
    bottomInset: useSmileIDSampleNavBarClearance(context),
  );
}
