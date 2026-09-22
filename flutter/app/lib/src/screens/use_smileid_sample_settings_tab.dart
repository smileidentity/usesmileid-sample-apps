import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../use_smileid_sample_routes.dart';
import '../use_smileid_sample_version.dart';

/// The settings tab, whose six switches survive a restart.
class UseSmileIDSampleSettingsTab extends ConsumerStatefulWidget {
  /// [openDrawer] is set by the deep link, which opens this page with the drawer already up.
  const UseSmileIDSampleSettingsTab({this.openDrawer = false, super.key});

  /// Whether a link asked for the scenario drawer.
  final bool openDrawer;

  @override
  ConsumerState<UseSmileIDSampleSettingsTab> createState() =>
      _UseSmileIDSampleSettingsTabState();
}

class _UseSmileIDSampleSettingsTabState
    extends ConsumerState<UseSmileIDSampleSettingsTab> {
  @override
  void initState() {
    super.initState();
    // After the first frame, because a sheet cannot be presented while this is still building —
    // and once only, so returning here later does not replay the link's sheet.
    if (widget.openDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openScenarioDrawer();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      onNavRowTap: _openNavRow,
      // Debug builds only; every flow reaches the drawer by its deep link instead.
      onOpenScenarioDrawer: kDebugMode ? _openScenarioDrawer : null,
      onSignOut: () {},
      bottomInset: useSmileIDSampleNavBarClearance(context),
    );
  }

  /// A row with no url is one this app renders, which today is the notices screen alone.
  void _openNavRow(UseSmileIDSampleNavRow row) {
    if (row.url == null) {
      context.go(UseSmileIDSampleRoutes.licenses);
    }
  }

  /// Hands the route back on dismiss, or a second delivery of the link reopens nothing.
  Future<void> _openScenarioDrawer() async {
    // Read before the await: an inherited lookup across the gap is what `mounted` does not cover.
    final GoRouter router = GoRouter.of(context);
    await _showScenarioDrawer();
    if (router.routerDelegate.currentConfiguration.uri.path ==
        UseSmileIDSampleRoutes.scenarioDrawer) {
      router.go(UseSmileIDSampleRoutes.settings);
    }
  }

  Future<void> _showScenarioDrawer() => showUseSmileIDSampleSheet<void>(
    context: context,
    title: 'Scenarios',
    testId: UseSmileIDSampleTestIds.scenarioDrawer,
    // A Consumer INSIDE the sheet: the outer `ref.watch` registers on this tab, so a selection
    // rebuilt the page behind the scrim while the open drawer kept its old checkmarks.
    builder: (BuildContext sheetContext) => Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? _) {
        final UseSmileIDSampleScenarioSelection selection = ref.watch(
          useSmileIDSampleScenarioProvider,
        );
        return UseSmileIDSampleScenarioDrawer(
          scenario: selection.scenario,
          theme: selection.theme,
          onScenarioSelected: ref
              .read(useSmileIDSampleScenarioProvider.notifier)
              .selectScenario,
          onThemeSelected: ref
              .read(useSmileIDSampleScenarioProvider.notifier)
              .selectTheme,
        );
      },
    ),
  );
}
