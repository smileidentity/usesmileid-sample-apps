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
    super.key,
  });

  /// Every profile, in hue order.
  final List<UseSmileIDSampleProfile> profiles;

  /// Which one is active.
  final String activeId;

  /// Switches to one; the owner closes the sheet.
  final void Function(UseSmileIDSampleProfile profile) onSelect;

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
            organisation: profiles[index].organisation,
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
      ],
    );
  }
}

/// The five fields a new profile needs, of which three gate the confirm.
class UseSmileIDSampleNewProfileSheet extends StatefulWidget {
  /// [onCreate] receives the organisation and the details; the owner closes the sheet.
  const UseSmileIDSampleNewProfileSheet({required this.onCreate, super.key});

  /// Creates the profile.
  final void Function(String organisation, UseSmileIDSampleUserDetails details)
  onCreate;

  @override
  State<UseSmileIDSampleNewProfileSheet> createState() =>
      _UseSmileIDSampleNewProfileSheetState();
}

class _UseSmileIDSampleNewProfileSheetState
    extends State<UseSmileIDSampleNewProfileSheet> {
  String _name = '';
  UseSmileIDSampleUserDetails _details = const UseSmileIDSampleUserDetails();

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
            placeholder: _sheetPlaceholders[field]!,
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

/// The sheet's own placeholders, which are shorter than the config page's prompts.
const Map<UseSmileIDSampleUserField, String> _sheetPlaceholders =
    <UseSmileIDSampleUserField, String>{
      UseSmileIDSampleUserField.firstName: 'First name',
      UseSmileIDSampleUserField.lastName: 'Last name',
      UseSmileIDSampleUserField.email: 'Email (optional)',
      UseSmileIDSampleUserField.phone: 'Phone (optional)',
    };

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
