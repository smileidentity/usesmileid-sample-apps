import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_avatar.dart';
import 'use_smileid_sample_glyphs.dart';

/// An organisation and a supporting line, with a check on the active profile.
///
/// The avatar fill is the caller's to pass, and its default is the same value [UseSmileIDSampleAvatar]
/// defaults to: two different defaults drew one profile navy in the list and blue in the summary.
class UseSmileIDSampleProfileRow extends StatelessWidget {
  /// [avatarColor] comes from `smileProfileHues` by list position, never from a hash of the name.
  const UseSmileIDSampleProfileRow({
    required this.organisation,
    required this.supportingText,
    required this.initials,
    required this.selected,
    required this.onTap,
    this.avatarColor,
    this.trailing,
    this.testId,
    super.key,
  });

  /// The profile's organisation, which the SDK's consent screen names as the partner.
  final String organisation;

  /// The person on the switch sheet, "Tap to configure" in settings.
  final String supportingText;

  /// The avatar's initials.
  final String initials;

  /// Whether this is the active profile.
  final bool selected;

  /// What a tap does.
  final VoidCallback onTap;

  /// The per-profile hue; the first hue when the caller has no position to colour by.
  final Color? avatarColor;

  /// Replaces the trailing check, which is how the add-a-profile variant draws its plus.
  final Widget? trailing;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final bool stacks = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Semantics(
      identifier: testId,
      selected: selected,
      child: Material(
        color: selected ? colors.surfaceTile : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmileDimens.radiusSurface),
          side: BorderSide(
            color: colors.cardStroke,
            width: smileCardStrokeWidth,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SmileDimens.radiusSurface),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SmileDimens.space64),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _rowPaddingX,
                vertical: SmileDimens.spacingSm,
              ),
              // A Row at the design's scale; a Wrap above it, so the trailing drops below rather
              // than squeezing the text column until a word breaks mid-word. The JobRow makes the
              // same trade for the same reason.
              child: stacks
                  ? Wrap(
                      spacing: SmileDimens.spacingSm,
                      runSpacing: SmileDimens.spacingXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        UseSmileIDSampleAvatar(
                          initials: initials,
                          size: SmileDimens.sizeControlMd,
                          containerColor: avatarColor ?? smileProfileHues.first,
                        ),
                        _RowText(
                          organisation: organisation,
                          supportingText: supportingText,
                          colors: colors,
                        ),
                        if (trailing != null) trailing!,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        UseSmileIDSampleAvatar(
                          initials: initials,
                          size: SmileDimens.sizeControlMd,
                          containerColor: avatarColor ?? smileProfileHues.first,
                        ),
                        const SizedBox(width: SmileDimens.spacingSm),
                        Expanded(
                          child: _RowText(
                            organisation: organisation,
                            supportingText: supportingText,
                            colors: colors,
                          ),
                        ),
                        if (trailing != null) ...<Widget>[
                          const SizedBox(width: SmileDimens.spacingSm),
                          trailing!,
                        ] else if (selected) ...<Widget>[
                          const SizedBox(width: SmileDimens.spacingSm),
                          SizedBox(
                            width: SmileDimens.sizeIconMd,
                            height: SmileDimens.sizeIconMd,
                            child: Center(
                              child: UseSmileIDSampleGlyphs.check(
                                colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's own padding, which no scale token carries.
const double _rowPaddingX = 14;

/// The organisation's run, a half-point off the nearest token.
const double _rowTitleSize = 14.5;

/// The row's two lines, shared by both layouts so they cannot drift apart.
class _RowText extends StatelessWidget {
  const _RowText({
    required this.organisation,
    required this.supportingText,
    required this.colors,
  });

  final String organisation;
  final String supportingText;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        organisation,
        style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
          fontSize: _rowTitleSize,
          color: colors.textTitle,
        ),
      ),
      const SizedBox(height: SmileDimens.spacingXxs),
      Text(
        supportingText,
        style: UseSmileIDSampleType.textStyleCaption.copyWith(
          color: colors.textMuted,
        ),
      ),
    ],
  );
}
