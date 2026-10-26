import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../navigation/use_smileid_sample_navigation.dart';
import '../state/use_smileid_sample_providers.dart';

/// The capture-mode sheet over settings; a pick is kept and closes it.
class UseSmileIDSampleCaptureModeStep extends ConsumerWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleCaptureModeStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      UseSmileIDSamplePartialSheetBody(
        title: context.strings.captureModeTitle,
        testId: UseSmileIDSampleTestIds.captureModeSheet,
        child: UseSmileIDSampleCaptureModeSheet(
          selected: ref.watch(useSmileIDSampleSettingsProvider).captureMode,
          onSelect: (UseSmileIDSampleCaptureMode mode) {
            unawaited(
              ref
                  .read(useSmileIDSampleSettingsProvider.notifier)
                  .setCaptureMode(mode),
            );
            unawaited(scope.navigator.back());
          },
        ),
      );
}

/// The appearance sheet over settings; a pick is kept and closes it.
class UseSmileIDSampleAppearanceStep extends ConsumerWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleAppearanceStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      UseSmileIDSamplePartialSheetBody(
        title: context.strings.appearanceTitle,
        testId: UseSmileIDSampleTestIds.appearanceSheet,
        child: UseSmileIDSampleAppearanceSheet(
          selected: ref.watch(useSmileIDSampleSettingsProvider).appearance,
          deviceDark:
              MediaQuery.platformBrightnessOf(context) == Brightness.dark,
          onSelect: (UseSmileIDSampleAppearance appearance) {
            unawaited(
              ref
                  .read(useSmileIDSampleSettingsProvider.notifier)
                  .setAppearance(appearance),
            );
            unawaited(scope.navigator.back());
          },
        ),
      );
}

/// The language sheet over settings; a pick is kept and closes it.
class UseSmileIDSampleLanguageStep extends ConsumerWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleLanguageStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      UseSmileIDSamplePartialSheetBody(
        title: context.strings.languageTitle,
        testId: UseSmileIDSampleTestIds.languageSheet,
        child: UseSmileIDSampleLanguageSheet(
          selected: ref.watch(useSmileIDSampleSettingsProvider).language,
          deviceLanguages: UseSmileIDSampleStringsScope.deviceLanguagesOf(
            context,
          ),
          onSelect: (UseSmileIDSampleLanguage language) {
            unawaited(
              ref
                  .read(useSmileIDSampleSettingsProvider.notifier)
                  .setLanguage(language),
            );
            unawaited(scope.navigator.back());
          },
        ),
      );
}

/// The scenario drawer over settings, which stays open while scenarios and themes are picked.
class UseSmileIDSampleScenarioDrawerStep extends ConsumerWidget {
  /// The drawer has no entry of its own to read: it closes by its scrim or a drag.
  const UseSmileIDSampleScenarioDrawerStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleScenarioSelection selection = ref.watch(
      useSmileIDSampleScenarioProvider,
    );
    return UseSmileIDSamplePartialSheetBody(
      title: 'Scenarios',
      testId: UseSmileIDSampleTestIds.scenarioDrawer,
      child: UseSmileIDSampleScenarioDrawer(
        scenario: selection.scenario,
        theme: selection.theme,
        onScenarioSelected: ref
            .read(useSmileIDSampleScenarioProvider.notifier)
            .selectScenario,
        onThemeSelected: ref
            .read(useSmileIDSampleScenarioProvider.notifier)
            .selectTheme,
      ),
    );
  }
}
