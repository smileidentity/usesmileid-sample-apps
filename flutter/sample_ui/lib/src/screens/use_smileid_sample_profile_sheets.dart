import 'package:flutter/material.dart';

import '../components/use_smileid_sample_avatar.dart';
import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_glyphs.dart';
import '../components/use_smileid_sample_profile_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_text_input.dart';
import '../state/use_smileid_sample_profiles.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// Switches the active profile: one tap, no confirm, and the sheet closes itself.
class UseSmileIDSampleProfileSwitchSheet extends StatelessWidget {
  /// Takes the whole list, because the hue is the profile's POSITION in it.
  const UseSmileIDSampleProfileSwitchSheet({
    required this.profiles,
    required this.activeId,
    required this.onSelect,
    this.onCreate,
    super.key,
  });

  /// Every profile, in hue order.
  final List<UseSmileIDSampleProfile> profiles;

  /// Which one is active; null while there are none.
  final String? activeId;

  /// Switches to one; the owner closes the sheet.
  final void Function(UseSmileIDSampleProfile profile) onSelect;

  /// Opens the new-profile sheet; null hides the row, for a host that offers no way to create one.
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Switch profile',
          style: UseSmileIDSampleType.textStyleHeadingSection.copyWith(
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        for (int index = 0; index < profiles.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: SmileDimens.spacingSm),
          UseSmileIDSampleProfileRow(
            organisation: profiles[index].title,
            supportingText: profiles[index].caption,
            initials: profiles[index].initials,
            selected: profiles[index].id == activeId,
            onTap: () => onSelect(profiles[index]),
            avatarColor: avatarColorForProfile(index),
            trailing: profiles[index].id == activeId
                ? UseSmileIDSampleGlyphs.check(colors.primary)
                : null,
            testId: UseSmileIDSampleTestIds.profileRow(profiles[index].id),
          ),
        ],
        if (onCreate != null) ...<Widget>[
          if (profiles.isNotEmpty)
            const SizedBox(height: SmileDimens.spacingSm),
          UseSmileIDSampleProfileRow(
            organisation: 'New profile',
            supportingText: 'Run jobs as someone else',
            initials: '',
            selected: false,
            onTap: onCreate!,
            testId: UseSmileIDSampleTestIds.profileSwitchNew,
          ),
        ],
      ],
    );
  }
}

/// The five fields a new profile needs, of which three gate the confirm.
class UseSmileIDSampleNewProfileSheet extends StatefulWidget {
  /// [onCreate] receives the organisation and the details; the owner closes the sheet.
  const UseSmileIDSampleNewProfileSheet({
    required this.onCreate,
    this.initialName = '',
    this.initialDetails = const UseSmileIDSampleUserDetails(),
    super.key,
  });

  /// Creates the profile.
  final void Function(String organisation, UseSmileIDSampleUserDetails details)
  onCreate;

  /// What a form had typed, so a profile created from it is not typed twice.
  final String initialName;

  /// The form's typed details, for the same reason.
  final UseSmileIDSampleUserDetails initialDetails;

  @override
  State<UseSmileIDSampleNewProfileSheet> createState() =>
      _UseSmileIDSampleNewProfileSheetState();
}

class _UseSmileIDSampleNewProfileSheetState
    extends State<UseSmileIDSampleNewProfileSheet> {
  late String _name = widget.initialName;
  late UseSmileIDSampleUserDetails _details = widget.initialDetails;

  /// Email and phone never gate it, which is the whole of the sheet's validation.
  bool get _canCreate =>
      _name.trim().isNotEmpty &&
      _details.firstName.trim().isNotEmpty &&
      _details.lastName.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'New profile',
          style: UseSmileIDSampleType.textStyleHeadingSection.copyWith(
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        UseSmileIDSampleTextInput(
          value: _name,
          onChanged: (String value) => setState(() => _name = value),
          placeholder: 'Profile name',
          testId: UseSmileIDSampleTestIds.newProfileName,
        ),
        const SizedBox(height: SmileDimens.spacingSm),
        const UseSmileIDSampleSectionLabel(text: 'USER DETAILS'),
        const SizedBox(height: SmileDimens.spacingXs),
        for (final UseSmileIDSampleUserField field
            in UseSmileIDSampleUserField.values) ...<Widget>[
          UseSmileIDSampleTextInput(
            value: field.valueOf(_details),
            onChanged: (String value) =>
                setState(() => _details = field.apply(_details, value)),
            placeholder: field.label,
            testId: _sheetTestIds[field]!,
          ),
          const SizedBox(height: SmileDimens.spacingSm),
        ],
        UseSmileIDSampleButton(
          text: 'Create profile',
          onPressed: () => widget.onCreate(_name.trim(), _details),
          enabled: _canCreate,
          testId: UseSmileIDSampleTestIds.newProfileSave,
        ),
      ],
    );
  }
}

/// The sheet's ids, which are snake_case where the config page's are camelCase.
const Map<UseSmileIDSampleUserField, String> _sheetTestIds =
    <UseSmileIDSampleUserField, String>{
      UseSmileIDSampleUserField.firstName:
          UseSmileIDSampleTestIds.newProfileFirstName,
      UseSmileIDSampleUserField.lastName:
          UseSmileIDSampleTestIds.newProfileLastName,
      UseSmileIDSampleUserField.email: UseSmileIDSampleTestIds.newProfileEmail,
      UseSmileIDSampleUserField.phone: UseSmileIDSampleTestIds.newProfilePhone,
    };
