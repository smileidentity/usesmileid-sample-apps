import 'package:flutter/material.dart';

import '../model/use_smileid_sample_product.dart';
import '../model/use_smileid_sample_status.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_icon.dart';
import 'use_smileid_sample_status_badge.dart';

/// One verification: a product tile, its name, a secondary line of job id and time, and the badge.
class UseSmileIDSampleJobRow extends StatelessWidget {
  /// [statusTestId] is defaulted rather than attached by the caller; a list overrides it per row.
  const UseSmileIDSampleJobRow({
    required this.product,
    required this.jobId,
    required this.time,
    required this.status,
    this.onTap,
    this.testId,
    this.statusTestId = UseSmileIDSampleTestIds.jobRowStatus,
    this.selected,
    this.trailing,
    super.key,
  });

  /// Which product the job ran.
  final UseSmileIDSampleProduct product;

  /// The job id, already elided by the caller.
  final String jobId;

  /// The submission time, already formatted.
  final String time;

  /// The job's status; null draws [trailing] in the badge's place.
  final UseSmileIDSampleStatus? status;

  /// What a tap does.
  final VoidCallback? onTap;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  /// The `sample_*` id for the badge, asserted on separately.
  final String? statusTestId;

  /// Non-null makes the row an option, with the primary border when true.
  final bool? selected;

  /// What sits where the badge would when there is no status.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // A Row at the design's scale keeps the badge inline; a Wrap above it lets the badge drop.
    // One layout cannot do both: a flexible child inside a Wrap claims the whole line.
    final bool stacks = MediaQuery.textScalerOf(context).scale(1) > 1;
    final Widget tile = UseSmileIDSampleProductTile(product: product);
    final UseSmileIDSampleStatus? shown = status;
    final Widget badge = shown != null
        ? UseSmileIDSampleStatusBadge(status: shown, testId: statusTestId)
        : trailing ?? const SizedBox.shrink();

    return Semantics(
      identifier: testId,
      button: onTap != null && selected == null,
      selected: selected,
      inMutuallyExclusiveGroup: selected != null,
      child: Material(
        color: colors.card.background,
        shape: RoundedRectangleBorder(
          borderRadius: UseSmileIDSampleShapes.card,
          side: selected == true
              ? BorderSide(
                  color: colors.primary,
                  width: SmileDimens.borderWidthThin,
                )
              : BorderSide(
                  color: colors.cardStroke,
                  width: smileCardStrokeWidth,
                ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: UseSmileIDSampleShapes.card,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SmileDimens.space64),
            child: Padding(
              padding: const EdgeInsets.all(SmileDimens.spacingSm),
              child: stacks
                  ? Wrap(
                      spacing: SmileDimens.spacingSm,
                      runSpacing: SmileDimens.spacingXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        tile,
                        _JobRowText(
                          product: product,
                          jobId: jobId,
                          time: time,
                          stacks: true,
                          colors: colors,
                        ),
                        badge,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        tile,
                        const SizedBox(width: SmileDimens.spacingSm),
                        Expanded(
                          child: _JobRowText(
                            product: product,
                            jobId: jobId,
                            time: time,
                            stacks: false,
                            colors: colors,
                          ),
                        ),
                        const SizedBox(width: SmileDimens.spacingSm),
                        badge,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A product's hue tile with its icon.
class UseSmileIDSampleProductTile extends StatelessWidget {
  /// The board's 36 tile with its 18 glyph.
  const UseSmileIDSampleProductTile({required this.product, super.key});

  /// Whose hue and icon the tile draws.
  final UseSmileIDSampleProduct product;

  @override
  Widget build(BuildContext context) {
    final SmileProductHue hue = productHue(product);
    return Container(
      width: _tileSize,
      height: _tileSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hue.tile,
        borderRadius: UseSmileIDSampleShapes.rowTile,
      ),
      child: UseSmileIDSampleIcon(
        asset: productIcon(product),
        tint: hue.icon,
        size: _tileIconSize,
      ),
    );
  }
}

class _JobRowText extends StatelessWidget {
  const _JobRowText({
    required this.product,
    required this.jobId,
    required this.time,
    required this.stacks,
    required this.colors,
  });

  final UseSmileIDSampleProduct product;
  final String jobId;
  final String time;
  final bool stacks;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(
        product.title(context.strings),
        // One line at the design's scale; enlarged type wraps, because eliding it would clip.
        maxLines: stacks ? null : 1,
        overflow: stacks ? null : TextOverflow.ellipsis,
        style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
          color: colors.card.title,
        ),
      ),
      const SizedBox(height: SmileDimens.spacingXxs),
      Text(
        '$jobId · $time',
        // Elided like the title, so every row is the same height at the design's scale.
        maxLines: stacks ? null : 1,
        overflow: stacks ? null : TextOverflow.ellipsis,
        // Caption, not body-sm: the board draws 12/16/500 and `spec/components.json` rules that a
        // port takes the board while Android, the only other implementation, follows.
        style: UseSmileIDSampleType.textStyleCaption.copyWith(
          color: colors.textMuted,
        ),
      ),
    ],
  );
}

/// The design's tile and glyph, both read off the board rather than the scale.
const double _tileSize = 36;
const double _tileIconSize = 18;
