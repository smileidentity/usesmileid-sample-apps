import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// A settings row: a glyph tile, a title with an optional supporting line, and a trailing control.
class UseSmileIDSampleSettingRow extends StatelessWidget {
  /// [leading] is handed the tint the tile resolves to, so no caller picks a colour.
  const UseSmileIDSampleSettingRow({
    required this.title,
    this.supportingText,
    this.onTap,
    this.leading,
    this.trailing,
    this.testId,
    super.key,
  });

  /// The row's title.
  final String title;

  /// The line beneath it, where the design draws one.
  final String? supportingText;

  /// What a tap does; absent on a row whose only control is its trailing one.
  final VoidCallback? onTap;

  /// The row's own mark, which the design supplies for all eleven rows.
  final Widget Function(Color tint)? leading;

  /// The switch or chevron at the end of the row.
  final Widget? trailing;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SmileDimens.space64),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SmileDimens.spacingMd,
          vertical: SmileDimens.spacingSm,
        ),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[
              Container(
                width: _tileSize,
                height: _tileSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // surface-2, a cool grey — surface-alt is a warm cream and drew peach tiles.
                  color: colors.surfaceTile,
                  borderRadius: BorderRadius.circular(_tileRadius),
                ),
                child: leading!(colors.textTitle),
              ),
              const SizedBox(width: SmileDimens.spacingSm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                      color: colors.textTitle,
                    ),
                  ),
                  if (supportingText != null) ...<Widget>[
                    const SizedBox(height: SmileDimens.spacingXxs),
                    Text(
                      supportingText!,
                      style: UseSmileIDSampleType.textStyleCaption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: SmileDimens.spacingSm),
              trailing!,
            ],
          ],
        ),
      ),
    );
    return Semantics(
      identifier: testId,
      button: onTap != null,
      child: onTap == null
          ? row
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: row),
            ),
    );
  }
}

/// The trailing chevron that says the row pushes a screen.
class UseSmileIDSampleSettingRowChevron extends StatelessWidget {
  /// Takes nothing; its size and tint are the design's.
  const UseSmileIDSampleSettingRowChevron({super.key});

  @override
  Widget build(BuildContext context) => UseSmileIDSampleGlyphs.chevronRight(
    UseSmileIDSampleTheme.colorsOf(context).textMuted,
    size: _chevronSize,
  );
}

/// The rule between rows inside one section card, on the same pair as the card's own outline.
class UseSmileIDSampleSettingRowDivider extends StatelessWidget {
  /// Takes nothing; the pair it draws is the one the card is outlined in.
  const UseSmileIDSampleSettingRowDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: smileCardStrokeWidth,
    thickness: smileCardStrokeWidth,
    color: UseSmileIDSampleTheme.colorsOf(context).cardStroke,
  );
}

/// Sign out: full width, centred, in the soft error text rather than the saturated fill.
class UseSmileIDSampleDestructiveRow extends StatelessWidget {
  /// Takes the copy, because "Sign out" is product text rather than a component's.
  const UseSmileIDSampleDestructiveRow({
    required this.text,
    required this.onTap,
    this.testId,
    super.key,
  });

  /// The action's label.
  final String text;

  /// What a tap does.
  final VoidCallback onTap;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: testId,
      button: true,
      child: Material(
        color: colors.surface,
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
            constraints: const BoxConstraints(
              minHeight: SmileDimens.sizeControlMd,
            ),
            child: Padding(
              padding: const EdgeInsets.all(SmileDimens.spacingSm),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  // The soft error text; errorFill is the saturated pill colour.
                  style: UseSmileIDSampleType.textStyleButton.copyWith(
                    color: colors.badge.errorText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The design's tile, which no scale token carries.
const double _tileSize = 38;
const double _tileRadius = 11;

/// The design's chevron, smaller than the icon scale's 16.
const double _chevronSize = 14;
