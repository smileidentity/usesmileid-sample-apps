import 'package:flutter/material.dart';

import '../components/use_smileid_sample_avatar.dart';
import '../components/use_smileid_sample_glyphs.dart';
import '../components/use_smileid_sample_profile_row.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_toast.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../state/use_smileid_sample_profiles.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// Every profile the app can act as, and the row that creates another.
class UseSmileIDSampleProfilesScreen extends StatelessWidget {
  /// [createdNotice] names the profile just created, and its action makes that profile active.
  const UseSmileIDSampleProfilesScreen({
    required this.profiles,
    required this.activeId,
    required this.onBack,
    required this.onProfileTap,
    required this.onCreate,
    this.createdNotice,
    this.onMakeCreatedActive,
    super.key,
  });

  /// Every profile, in the order that decides their avatar hues.
  final List<UseSmileIDSampleProfile> profiles;

  /// Which one is active; the list marks it in the caption rather than with a fill.
  final String activeId;

  /// Leaves the screen.
  final VoidCallback onBack;

  /// Opens one profile's own page.
  final void Function(UseSmileIDSampleProfile profile) onProfileTap;

  /// Opens the new-profile sheet.
  final VoidCallback onCreate;

  /// The organisation just created, or null when no confirmation stands.
  final String? createdNotice;

  /// Makes the just-created profile active; the confirmation carries the offer.
  final VoidCallback? onMakeCreatedActive;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final Widget page = Semantics(
      identifier: UseSmileIDSampleTestIds.profilesScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(title: 'Profiles', onBack: onBack),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
              ),
              children: <Widget>[
                for (
                  int index = 0;
                  index < profiles.length;
                  index++
                ) ...<Widget>[
                  UseSmileIDSampleProfileRow(
                    organisation: profiles[index].organisation,
                    // The ONLY marker of the active profile on this screen: the design gives the
                    // list no fill and no check, unlike the switch sheet.
                    supportingText: profiles[index].id == activeId
                        ? '${profiles[index].caption}$_activeSuffix'
                        : profiles[index].caption,
                    initials: profiles[index].initials,
                    selected: false,
                    onTap: () => onProfileTap(profiles[index]),
                    avatarColor: avatarColorForProfile(index),
                    trailing: const UseSmileIDSampleSettingRowChevron(),
                    testId: UseSmileIDSampleTestIds.profileRow(
                      profiles[index].id,
                    ),
                  ),
                  const SizedBox(height: SmileDimens.spacingXs),
                ],
                _CreateRow(onTap: onCreate, colors: colors),
              ],
            ),
          ),
        ],
      ),
    );
    if (createdNotice == null) {
      return page;
    }
    return Stack(
      children: <Widget>[
        page,
        Positioned(
          left: SmileDimens.spacingMd,
          right: SmileDimens.spacingMd,
          bottom: SmileDimens.spacingLg,
          child: UseSmileIDSampleToast(
            message: '$createdNotice created',
            actionLabel: 'Make active',
            onAction: onMakeCreatedActive,
          ),
        ),
      ],
    );
  }
}

/// The last row: no card and no border, because it is an action rather than a profile.
class _CreateRow extends StatelessWidget {
  const _CreateRow({required this.onTap, required this.colors});

  final VoidCallback onTap;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: UseSmileIDSampleTestIds.createProfile,
    button: true,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _createPaddingX,
          vertical: SmileDimens.spacingSm,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: _tileSize,
              height: _tileSize,
              decoration: BoxDecoration(
                color: colors.badge.infoBackground,
                borderRadius: BorderRadius.circular(SmileDimens.radiusMd),
              ),
              child: Center(child: UseSmileIDSampleGlyphs.plus(colors.primary)),
            ),
            const SizedBox(width: SmileDimens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Create new profile',
                    style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                      fontSize: _createTitleSize,
                      color: colors.textTitle,
                    ),
                  ),
                  const SizedBox(height: SmileDimens.spacingXxs),
                  Text(
                    'Its user details will live under it',
                    style: UseSmileIDSampleType.textStyleCaption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// What the list appends to the active profile's caption.
const String _activeSuffix = ' · active';

/// The create row's tile, read off the board rather than the icon scale.
const double _tileSize = 44;

/// The create row's own inset and title run, which no scale token carries.
const double _createPaddingX = 14;
const double _createTitleSize = 14.5;
