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
import '../use_smileid_sample_test_ids.dart';

/// How the SDK photographs the document; choosing Custom hands over to the custom-document sheet.
class UseSmileIDSampleCaptureAsSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses.
  const UseSmileIDSampleCaptureAsSheet({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  /// The option already chosen.
  final UseSmileIDSampleCaptureAs selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleCaptureAs> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final UseSmileIDSampleCaptureAs option
          in UseSmileIDSampleCaptureAs.values)
        UseSmileIDSampleOptionRow(
          label: option.label,
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
          label: mode.label,
          selected: mode == selected,
          onTap: () => onSelect(mode),
          testId: UseSmileIDSampleTestIds.captureModeOption(mode.id),
        ),
    ],
  );
}

/// Builds the generic document "Capture as: Custom" hands the SDK; nothing is kept until Done.
class UseSmileIDSampleCustomDocumentSheet extends StatefulWidget {
  /// [initial] seeds the draft.
  const UseSmileIDSampleCustomDocumentSheet({
    required this.initial,
    required this.onDone,
    super.key,
  });

  /// What the form already holds.
  final UseSmileIDSampleCustomDocument initial;

  /// Keeps the draft and dismisses.
  final ValueChanged<UseSmileIDSampleCustomDocument> onDone;

  @override
  State<UseSmileIDSampleCustomDocumentSheet> createState() =>
      _UseSmileIDSampleCustomDocumentSheetState();
}

class _UseSmileIDSampleCustomDocumentSheetState
    extends State<UseSmileIDSampleCustomDocumentSheet> {
  late UseSmileIDSampleCustomDocument _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const UseSmileIDSampleSectionLabel(text: 'DISPLAY NAME'),
        const SizedBox(height: SmileDimens.spacingSm),
        UseSmileIDSampleTextInput(
          value: _draft.displayName,
          onChanged: (String value) =>
              setState(() => _draft = _draft.copyWith(displayName: value)),
          placeholder: 'Document',
          testId: UseSmileIDSampleTestIds.customDocumentName,
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        UseSmileIDSampleSettingRow(
          title: 'Back side',
          supportingText: 'Capture the back after the front',
          trailing: UseSmileIDSampleSwitch(
            value: _draft.hasBackSide,
            onChanged: (bool value) =>
                setState(() => _draft = _draft.copyWith(hasBackSide: value)),
            testId: UseSmileIDSampleTestIds.customDocumentBackSide,
          ),
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        const UseSmileIDSampleSectionLabel(text: 'ORIENTATION'),
        const SizedBox(height: SmileDimens.spacingSm),
        Wrap(
          spacing: SmileDimens.spacingXs,
          runSpacing: SmileDimens.spacingXs,
          children: <Widget>[
            for (final UseSmileIDSampleDocumentOrientation orientation
                in UseSmileIDSampleDocumentOrientation.values)
              UseSmileIDSampleFilterChip(
                label: orientation.label,
                count: null,
                selected: orientation == _draft.orientation,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(orientation: orientation),
                ),
                testId: UseSmileIDSampleTestIds.customDocumentOrientation(
                  orientation.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        const UseSmileIDSampleSectionLabel(text: 'ASPECT RATIO'),
        const SizedBox(height: SmileDimens.spacingSm),
        Wrap(
          spacing: SmileDimens.spacingXs,
          runSpacing: SmileDimens.spacingXs,
          children: <Widget>[
            for (final UseSmileIDSampleAspectRatio ratio
                in UseSmileIDSampleAspectRatio.values)
              UseSmileIDSampleFilterChip(
                label: ratio.label,
                count: null,
                selected: ratio == _draft.aspectRatio,
                onTap: () => setState(
                  () => _draft = _draft.copyWith(aspectRatio: ratio),
                ),
                testId: UseSmileIDSampleTestIds.customDocumentAspectRatio(
                  ratio.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: SmileDimens.spacingMd),
        UseSmileIDSampleButton(
          text: 'Done',
          onPressed: () {
            final String name = _draft.displayName.trim();
            widget.onDone(
              _draft.copyWith(displayName: name.isEmpty ? 'Document' : name),
            );
          },
          testId: UseSmileIDSampleTestIds.customDocumentDone,
        ),
      ],
    );
  }
}
