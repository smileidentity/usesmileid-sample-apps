import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../navigation/use_smileid_sample_navigation.dart';
import '../state/use_smileid_sample_providers.dart';
import '../use_smileid_sample_shell_extension.dart';

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

/// A sheet the extension draws for one of its DEBUG rows; a release build, no extension or an unknown id closes it at once.
class UseSmileIDSampleDebugSheetStep extends ConsumerStatefulWidget {
  /// Draws the sheet [sheetId] names; [onDismiss] closes it.
  const UseSmileIDSampleDebugSheetStep({
    required this.sheetId,
    required this.onDismiss,
    super.key,
  });

  /// The sheet the extension's row asked for.
  final String sheetId;

  /// Closes the sheet.
  final VoidCallback onDismiss;

  @override
  ConsumerState<UseSmileIDSampleDebugSheetStep> createState() =>
      _UseSmileIDSampleDebugSheetStepState();
}

class _UseSmileIDSampleDebugSheetStepState
    extends ConsumerState<UseSmileIDSampleDebugSheetStep> {
  @override
  void initState() {
    super.initState();
    // Decided once, so a rebuild before the step leaves can't close a second entry.
    final bool opens = useSmileIDSampleDebugSheetOpens(
      debugBuild: kDebugMode,
      extension: ref.read(useSmileIDSampleShellExtensionProvider),
      sheetId: widget.sheetId,
    );
    if (!opens) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDismiss());
    }
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleShellExtension? extension = ref.watch(
      useSmileIDSampleShellExtensionProvider,
    );
    return useSmileIDSampleDebugSheetOpens(
          debugBuild: kDebugMode,
          extension: extension,
          sheetId: widget.sheetId,
        )
        ? extension!.debugSheet(widget.sheetId, widget.onDismiss)
        : const SizedBox.shrink();
  }
}
