import 'package:flutter/material.dart';

import '../model/use_smileid_sample_product.dart';
import '../model/use_smileid_sample_status.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_icon.dart';
import 'use_smileid_sample_status_badge.dart';

/// One verification: a product tile, its name, a secondary line of job id and time, and the badge.
///
/// Select mode's checkbox is not a slot — the design puts it beside the card, and inside it cost
/// the title its width.
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
    super.key,
  });

  /// Which product the job ran.
  final UseSmileIDSampleProduct product;

  /// The job id, already elided by the caller.
  final String jobId;

  /// The submission time, already formatted.
  final String time;

  /// The job's status.
  final UseSmileIDSampleStatus status;

  /// What a tap does.
  final VoidCallback? onTap;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  /// The `sample_*` id for the badge, asserted on separately.
  final String? statusTestId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // A Row at the design's scale keeps the badge inline; a Wrap above it lets the badge drop.
    // One layout cannot do both: a flexible child inside a Wrap claims the whole line.
    final bool stacks = MediaQuery.textScalerOf(context).scale(1) > 1;
    final Widget tile = _JobRowTile(product: product);
    final Widget badge = UseSmileIDSampleStatusBadge(
      status: status,
      testId: statusTestId,
    );

    return Semantics(
      identifier: testId,
      button: onTap != null,
      child: Material(
        color: colors.card.background,
        shape: RoundedRectangleBorder(
          borderRadius: UseSmileIDSampleShapes.card,
          side: BorderSide(
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

class _JobRowTile extends StatelessWidget {
  const _JobRowTile({required this.product});

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
        product.label,
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
        style: UseSmileIDSampleType.textStyleBodySm.copyWith(
          color: colors.textMuted,
        ),
      ),
    ],
  );
}

/// The design's tile and glyph, both read off the board rather than the scale.
const double _tileSize = 36;
const double _tileIconSize = 18;
