import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../navigation/use_smileid_sample_navigation.dart';
import '../navigation/use_smileid_sample_njia.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_shell_extension.dart';
import '../use_smileid_sample_version.dart';

/// The settings tab, whose switches and capture mode survive a restart.
class UseSmileIDSampleSettingsTab extends ConsumerStatefulWidget {
  /// The tab's root, for [scope]'s entry.
  const UseSmileIDSampleSettingsTab({required this.scope, super.key});

  /// The tab root's entry, which its rows go from.
  final UseSmileIDSampleStepScope scope;

  @override
  ConsumerState<UseSmileIDSampleSettingsTab> createState() =>
      _UseSmileIDSampleSettingsTabState();
}

class _UseSmileIDSampleSettingsTabState
    extends ConsumerState<UseSmileIDSampleSettingsTab> {
  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    return UseSmileIDSampleSettingsScreen(
      state: UseSmileIDSampleSettingsState(
        settings: ref.watch(useSmileIDSampleSettingsProvider),
        organisation:
            profiles.active?.title(context.strings) ??
            context.strings.profilesNoProfile,
        initials: profiles.active?.initials ?? '',
        versionLabel: useSmileIDSampleVersionLabel,
        avatarColor: avatarColorForProfile(profiles.activeIndex),
        hasProfile: profiles.active != null,
        // The platform's own brightness, which the app's theme mode never overrides.
        deviceDark: MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        consentBoundByToken:
            ref.watch(useSmileIDSampleSessionProvider).live?.bindings.consent !=
                null &&
            !useSmileIDSampleStartsExpired(
              ref.watch(useSmileIDSampleScenarioProvider).scenario,
            ),
      ),
      onSettingChanged: (UseSmileIDSampleSetting setting, bool enabled) => ref
          .read(useSmileIDSampleSettingsProvider.notifier)
          .setSetting(setting, enabled),
      // The LIST, not the active profile's own page: the twin's row is a way into every profile.
      onProfileTap: () => _go(UseSmileIDSampleStep.profiles),
      onNavRowTap: _openNavRow,
      onCaptureModeTap: () => _go(UseSmileIDSampleStep.captureMode),
      onAppearanceTap: () => _go(UseSmileIDSampleStep.appearance),
      onLanguageTap: () => _go(UseSmileIDSampleStep.language),
      // Debug builds only; every flow reaches the drawer by its deep link instead.
      onOpenScenarioDrawer: kDebugMode
          ? () => _go(UseSmileIDSampleStep.scenarioDrawer)
          : null,
      debugRows:
          ref.watch(useSmileIDSampleShellExtensionProvider)?.debugRows() ??
          const <Widget>[],
      onSignOut: () {
        unawaited(ref.read(useSmileIDSampleSessionProvider.notifier).clear());
        ref.read(useSmileIDSampleFormsProvider.notifier).clear();
        ref.read(useSmileIDSampleProfilesProvider.notifier).clear();
        unawaited(
          UseSmileIDSampleNavigationScope.engineOf(context).leaveToProducts(),
        );
      },
      bottomInset: useSmileIDSampleNavBarClearance(context),
    );
  }

  /// A row with no url is one this app renders, which today is the notices screen alone.
  void _openNavRow(UseSmileIDSampleNavRow row) {
    final String? url = row.url;
    if (url == null) {
      _go(UseSmileIDSampleStep.licenses);
      return;
    }
    unawaited(useSmileIDSampleOpenLink(Uri.parse(url), inApp: row.opensInApp));
  }

  /// Goes to [step] from this tab's root.
  void _go(UseSmileIDSampleStep step) =>
      unawaited(widget.scope.navigator.goStep(step));
}

/// Opens a link row: in-app browser, never a WebView, except the legal PDFs an in-app browser shows as a stub.
Future<void> useSmileIDSampleOpenLink(
  Uri url, {
  required bool inApp,
  Future<bool> Function(Uri, {LaunchMode mode}) launch = launchUrl,
}) async {
  try {
    final bool opened = await launch(
      url,
      mode: inApp
          ? LaunchMode.inAppBrowserView
          : LaunchMode.externalApplication,
    );
    // A device with no in-app browser answers false rather than throwing.
    if (!opened && inApp) {
      await launch(url, mode: LaunchMode.externalApplication);
    }
  } on Object catch (error) {
    // No browser, or a scheme nothing claims: a release build would crash on the unawaited throw.
    debugPrint('could not open $url: $error');
  }
}
