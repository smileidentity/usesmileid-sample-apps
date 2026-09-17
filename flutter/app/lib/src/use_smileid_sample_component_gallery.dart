import 'package:flutter/material.dart';
import 'package:sample_ui/sample_ui.dart';

/// Every primitive in one scrollable page, so each one has a call site and a device can be driven
/// over it before the screens that consume it exist. A dev surface, which is why it lives here.
class UseSmileIDSampleComponentGallery extends StatefulWidget {
  /// Takes nothing; the gallery owns the state its controls need.
  const UseSmileIDSampleComponentGallery({super.key});

  @override
  State<UseSmileIDSampleComponentGallery> createState() =>
      _UseSmileIDSampleComponentGalleryState();
}

class _UseSmileIDSampleComponentGalleryState
    extends State<UseSmileIDSampleComponentGallery> {
  String _idNumber = '';
  String _query = '';
  bool _agentMode = false;
  bool _loading = false;
  String? _country;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(SmileDimens.spacingMd),
          children: <Widget>[
            const UseSmileIDSampleSectionLabel(text: 'AVATAR'),
            const SizedBox(height: SmileDimens.spacingXs),
            Row(
              children: <Widget>[
                for (
                  int index = 0;
                  index < smileProfileHues.length;
                  index++
                ) ...<Widget>[
                  if (index > 0) const SizedBox(width: SmileDimens.spacingXs),
                  UseSmileIDSampleAvatar(
                    initials: 'P${index + 1}',
                    containerColor: avatarColorForProfile(index),
                  ),
                ],
                const SizedBox(width: SmileDimens.spacingXs),
                const UseSmileIDSampleAvatar(initials: ''),
              ],
            ),
            const SizedBox(height: SmileDimens.spacingLg),

            const UseSmileIDSampleSectionLabel(text: 'BUTTON'),
            const SizedBox(height: SmileDimens.spacingXs),
            UseSmileIDSampleButton(
              text: 'Continue',
              onPressed: () => setState(() => _loading = !_loading),
              loading: _loading,
            ),
            const SizedBox(height: SmileDimens.spacingXs),
            UseSmileIDSampleButton(
              text: 'Continue',
              onPressed: () {},
              enabled: false,
            ),
            const SizedBox(height: SmileDimens.spacingLg),

            const UseSmileIDSampleSectionLabel(text: 'TEXT INPUT'),
            const SizedBox(height: SmileDimens.spacingXs),
            UseSmileIDSampleTextInput(
              value: _idNumber,
              onChanged: (String value) => setState(() => _idNumber = value),
              placeholder: 'ID number',
              isError: _idNumber.isNotEmpty && _idNumber.length < 4,
              errorMessage: 'Enter a valid ID number',
            ),
            const SizedBox(height: SmileDimens.spacingLg),

            const UseSmileIDSampleSectionLabel(text: 'SEARCH FIELD'),
            const SizedBox(height: SmileDimens.spacingXs),
            UseSmileIDSampleSearchField(
              query: _query,
              onQueryChanged: (String value) => setState(() => _query = value),
              placeholder: 'Search country',
            ),
            const SizedBox(height: SmileDimens.spacingLg),

            const UseSmileIDSampleSectionLabel(text: 'SWITCH'),
            const SizedBox(height: SmileDimens.spacingXs),
            Row(
              children: <Widget>[
                UseSmileIDSampleSwitch(
                  value: _agentMode,
                  onChanged: (bool value) => setState(() => _agentMode = value),
                ),
                const SizedBox(width: SmileDimens.spacingXs),
                const UseSmileIDSampleSwitch(
                  value: true,
                  onChanged: null,
                  enabled: false,
                ),
              ],
            ),
            const SizedBox(height: SmileDimens.spacingLg),

            const UseSmileIDSampleSectionLabel(text: 'STATUS BADGE'),
            const SizedBox(height: SmileDimens.spacingXs),
            Wrap(
              spacing: SmileDimens.spacingXs,
              runSpacing: SmileDimens.spacingXs,
              children: <Widget>[
                for (final UseSmileIDSampleStatus status
                    in UseSmileIDSampleStatus.values)
                  UseSmileIDSampleStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: SmileDimens.spacingLg),

            const UseSmileIDSampleSectionLabel(text: 'TOAST'),
            const SizedBox(height: SmileDimens.spacingXs),
            UseSmileIDSampleToast(
              message: '1 verification hidden from App list',
              actionLabel: 'Undo',
              onAction: () {},
            ),
            const SizedBox(height: SmileDimens.spacingLg),

            // The only components that draw an emoji, so this is where a device run can see whether
            // the platform's emoji faces survived naming a bundled font family.
            const UseSmileIDSampleSectionLabel(text: 'COUNTRY PICKER'),
            const SizedBox(height: SmileDimens.spacingXs),
            UseSmileIDSampleSelectTrigger(
              value: _country,
              placeholder: 'Select country',
              onTap: () => setState(() => _country = null),
              leading: (Color tint) => UseSmileIDSampleTriggerEmoji(
                emoji: _country == null ? '🌍' : '🇰🇪',
              ),
            ),
            const SizedBox(height: SmileDimens.spacingXs),
            UseSmileIDSampleOptionRow(
              label: 'Kenya',
              leadingText: '🇰🇪',
              selected: _country == 'Kenya',
              onTap: () => setState(() => _country = 'Kenya'),
            ),
            UseSmileIDSampleOptionRow(
              label: 'Ghana',
              leadingText: '🇬🇭',
              selected: _country == 'Ghana',
              onTap: () => setState(() => _country = 'Ghana'),
            ),
          ],
        ),
      ),
    );
  }
}
