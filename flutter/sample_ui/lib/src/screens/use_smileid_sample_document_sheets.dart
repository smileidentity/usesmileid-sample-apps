import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_filter_chip.dart';
import '../components/use_smileid_sample_option_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_switch.dart';
import '../components/use_smileid_sample_text_input.dart';
import '../state/use_smileid_sample_id_details.dart';
import '../state/use_smileid_sample_settings.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// How the SDK photographs the document: Match document first, then the overrides; Generic document hands over to its sheet.
class UseSmileIDSampleCaptureAsSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses.
  const UseSmileIDSampleCaptureAsSheet({
    required this.selected,
    required this.matched,
    required this.onSelect,
    super.key,
  });

  /// The override already chosen; null is Match document.
  final UseSmileIDSampleCaptureAs? selected;

  /// What Match document resolves to for the chosen row, which its row names.
  final UseSmileIDSampleResolvedCaptureAs matched;

  /// Chooses one; null is Match document.
  final ValueChanged<UseSmileIDSampleCaptureAs?> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      UseSmileIDSampleOptionRow(
        label: matched.matchRowLabel(context.strings),
        selected: selected == null,
        onTap: () => onSelect(null),
        testId: UseSmileIDSampleTestIds.captureAsOption(
          UseSmileIDSampleCaptureAs.matchDocumentId,
        ),
      ),
      for (final UseSmileIDSampleCaptureAs option
          in UseSmileIDSampleCaptureAs.values)
        UseSmileIDSampleOptionRow(
          label: option.label(context.strings),
          selected: option == selected,
          onTap: () => onSelect(option),
          testId: UseSmileIDSampleTestIds.captureAsOption(option.id),
        ),
    ],
  );
}

/// DocumentCaptureConfig's capture mode; the fallback keeps the SDK's 10 seconds.
class UseSmileIDSampleCaptureModeSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses.
  const UseSmileIDSampleCaptureModeSheet({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  /// The mode already chosen.
  final UseSmileIDSampleCaptureMode selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleCaptureMode> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final UseSmileIDSampleCaptureMode mode
          in UseSmileIDSampleCaptureMode.values)
        UseSmileIDSampleOptionRow(
          label: mode.label(context.strings),
          selected: mode == selected,
          onTap: () => onSelect(mode),
          testId: UseSmileIDSampleTestIds.captureModeOption(mode.id),
        ),
    ],
  );
}

/// The three appearances; System's label names [deviceDark], the device's own theme.
class UseSmileIDSampleAppearanceSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses.
  const UseSmileIDSampleAppearanceSheet({
    required this.selected,
    required this.deviceDark,
    required this.onSelect,
    super.key,
  });

  /// The appearance already chosen.
  final UseSmileIDSampleAppearance selected;

  /// The device's own theme, never the one the app renders.
  final bool deviceDark;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleAppearance> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final UseSmileIDSampleAppearance appearance
          in UseSmileIDSampleAppearance.values)
        UseSmileIDSampleOptionRow(
          label: appearance.label(context.strings, deviceDark: deviceDark),
          selected: appearance == selected,
          onTap: () => onSelect(appearance),
          testId: UseSmileIDSampleTestIds.appearanceOption(appearance.id),
        ),
    ],
  );
}

/// Builds the generic document "Capture as: Generic document" hands the SDK; nothing is kept until Done.
class UseSmileIDSampleGenericDocumentSheet extends StatefulWidget {
  /// [initial] seeds the draft.
  const UseSmileIDSampleGenericDocumentSheet({
    required this.initial,
    required this.onDone,
    super.key,
  });

  /// What the form already holds.
  final UseSmileIDSampleGenericDocument initial;

  /// Keeps the draft and dismisses.
  final ValueChanged<UseSmileIDSampleGenericDocument> onDone;

  @override
  State<UseSmileIDSampleGenericDocumentSheet> createState() =>
      _UseSmileIDSampleGenericDocumentSheetState();
}

class _UseSmileIDSampleGenericDocumentSheetState
    extends State<UseSmileIDSampleGenericDocumentSheet> {
  late UseSmileIDSampleGenericDocument _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UseSmileIDSampleSectionLabel(
          text: context.strings.genericDocumentDisplayName,
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        UseSmileIDSampleTextInput(
          value: _draft.displayName,
          onChanged: (String value) =>
              setState(() => _draft = _draft.copyWith(displayName: value)),
          placeholder: context.strings.productCardDocument,
          testId: UseSmileIDSampleTestIds.genericDocumentName,
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        UseSmileIDSampleSettingRow(
          title: context.strings.genericDocumentBackSide,
          supportingText: context.strings.genericDocumentBackSideHint,
          trailing: UseSmileIDSampleSwitch(
            value: _draft.hasBackSide,
            onChanged: (bool value) =>
                setState(() => _draft = _draft.copyWith(hasBackSide: value)),
            testId: UseSmileIDSampleTestIds.genericDocumentBackSide,
          ),
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        UseSmileIDSampleSectionLabel(
          text: context.strings.genericDocumentOrientation,
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        Wrap(
          spacing: SmileDimens.spacingXs,
          runSpacing: SmileDimens.spacingXs,
          children: <Widget>[
            for (final UseSmileIDSampleDocumentOrientation orientation
                in UseSmileIDSampleDocumentOrientation.values)
              UseSmileIDSampleFilterChip(
                label: orientation.label(context.strings),
                count: null,
                selected: orientation == _draft.orientation,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(orientation: orientation),
                ),
                testId: UseSmileIDSampleTestIds.genericDocumentOrientation(
                  orientation.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        UseSmileIDSampleSectionLabel(
          text: context.strings.genericDocumentAspectRatio,
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        Wrap(
          spacing: SmileDimens.spacingXs,
          runSpacing: SmileDimens.spacingXs,
          children: <Widget>[
            for (final UseSmileIDSampleAspectRatio ratio
                in UseSmileIDSampleAspectRatio.values)
              UseSmileIDSampleFilterChip(
                label: ratio.label(context.strings),
                count: null,
                selected: ratio == _draft.aspectRatio,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(aspectRatio: ratio),
                ),
                testId: UseSmileIDSampleTestIds.genericDocumentAspectRatio(
                  ratio.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: SmileDimens.spacingMd),
        UseSmileIDSampleButton(
          text: context.strings.commonDone,
          onPressed: () {
            final String name = _draft.displayName.trim();
            widget.onDone(
              _draft.copyWith(
                displayName: name.isEmpty
                    ? context.strings.productCardDocument
                    : name,
              ),
            );
          },
          testId: UseSmileIDSampleTestIds.genericDocumentDone,
        ),
      ],
    );
  }
}

/// System, then each shipped language under its own name.
class UseSmileIDSampleLanguageSheet extends StatelessWidget {
  /// [onSelect] receives the language tapped.
  const UseSmileIDSampleLanguageSheet({
    required this.selected,
    required this.deviceLanguages,
    required this.onSelect,
    super.key,
  });

  /// The language already chosen.
  final UseSmileIDSampleLanguage selected;

  /// The device's languages, which the System row resolves.
  final List<String> deviceLanguages;

  /// Called with the language tapped.
  final ValueChanged<UseSmileIDSampleLanguage> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final UseSmileIDSampleLanguage language
          in UseSmileIDSampleLanguage.values)
        UseSmileIDSampleOptionRow(
          label: language.label(context.strings, deviceLanguages),
          selected: language == selected,
          onTap: () => onSelect(language),
          testId: UseSmileIDSampleTestIds.languageOption(language.id),
        ),
    ],
  );
}
