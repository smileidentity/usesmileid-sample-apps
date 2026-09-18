import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// A product tile: a gradient in the product's hue, a hairline stroke, its icon as a watermark.
class UseSmileIDSampleProductCard extends StatelessWidget {
  /// [ghost] is the same mark as [icon], drawn large and faint bleeding off the top-right.
  const UseSmileIDSampleProductCard({
    required this.title,
    required this.family,
    required this.hue,
    required this.onTap,
    this.enabled = true,
    this.icon,
    this.ghost,
    this.testId,
    super.key,
  });

  /// The card's first run, already shortened by the spec to fit its column.
  final String title;

  /// The card's second run.
  final String family;

  /// The product's colouring.
  final SmileProductHue hue;

  /// What a tap does.
  final VoidCallback onTap;

  /// Whether the product can be started.
  final bool enabled;

  /// The mark in the white tile, handed the hue's card-icon tint.
  final Widget Function(Color tint)? icon;

  /// The watermark, handed the ink that contrasts with the gradient's first stop.
  final Widget Function(Color tint)? ghost;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // A hue is the same in both schemes, so anything drawn on it resolves from the light one.
    final Color tile = enabled ? SmileColorLight.colorSurface : colors.surface;
    // Every card's text and arrow are white per the frame; consistency across the six beats
    // per-card contrast, and the fix for the light fills belongs in the fill.
    final Color content = enabled
        ? SmileColorLight.colorTextInverse
        : colors.textMuted;
    // The two marks the design fixes DO adapt, because one fixed value leaves the go pill
    // invisible on the darkest card and the ghost invisible on the lightest.
    final Color ghostInk = _inkOn(_gradientStart(hue));
    final Color goScrim = enabled
        ? _inkOn(_gradientEnd(hue))
        : colors.textMuted;

    return Semantics(
      identifier: testId,
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: UseSmileIDSampleShapes.card,
          side: BorderSide(
            color: colors.cardStroke,
            width: smileCardStrokeWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? _fill(hue) : null,
            color: enabled ? null : colors.surfaceMuted,
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _cardMinHeight),
              child: Stack(
                children: <Widget>[
                  if (ghost != null)
                    Positioned(
                      top: -SmileDimens.spacingXs,
                      right: -SmileDimens.spacingMd,
                      child: ghost!(ghostInk.withValues(alpha: _ghostAlpha)),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(SmileDimens.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: SmileDimens.space40,
                          height: SmileDimens.space40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tile,
                            borderRadius: UseSmileIDSampleShapes.tile,
                          ),
                          child: icon == null
                              ? UseSmileIDSampleGlyphs.productMark(hue.cardIcon)
                              : icon!(hue.cardIcon),
                        ),
                        const SizedBox(height: SmileDimens.spacingLg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: _CardLabel(
                                title: title,
                                family: family,
                                color: content,
                              ),
                            ),
                            const SizedBox(width: SmileDimens.spacingXs),
                            _GoAffordance(tint: content, scrim: goScrim),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One text node with two runs, not two stacked widgets, which drift apart at large font scales.
class _CardLabel extends StatelessWidget {
  const _CardLabel({
    required this.title,
    required this.family,
    required this.color,
  });

  final String title;
  final String family;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = UseSmileIDSampleType.textStyleBodyStrong;
    final TextStyle familyStyle = UseSmileIDSampleType.textStyleCaption;
    return Text.rich(
      _label(
        title: title,
        family: family,
        titleStyle: titleStyle,
        familyStyle: familyStyle,
        size: titleStyle.fontSize!,
      ),
      style: titleStyle.copyWith(
        color: color,
        letterSpacing: smileCardTitleTracking,
      ),
    );
  }
}

/// The two runs, the family scaled in proportion to the title.
TextSpan _label({
  required String title,
  required String family,
  required TextStyle titleStyle,
  required TextStyle familyStyle,
  required double size,
}) {
  final double ratio = familyStyle.fontSize! / titleStyle.fontSize!;
  return TextSpan(
    children: <InlineSpan>[
      TextSpan(
        text: title,
        style: TextStyle(height: titleStyle.height),
      ),
      TextSpan(
        text: '\n$family',
        style: TextStyle(
          fontSize: size * ratio,
          fontWeight: FontWeight.values[smileCardFamilyWeight ~/ 100 - 1],
          height: familyStyle.height,
        ),
      ),
    ],
  );
}

/// The circular arrow bottom-right, on a scrim the fill decides rather than a fixed value.
class _GoAffordance extends StatelessWidget {
  const _GoAffordance({required this.tint, required this.scrim});

  final Color tint;
  final Color scrim;

  @override
  Widget build(BuildContext context) => Container(
    width: SmileDimens.sizeIconLg,
    height: SmileDimens.sizeIconLg,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: scrim.withValues(alpha: _scrimAlpha),
    ),
    child: UseSmileIDSampleGlyphs.arrowForward(tint),
  );
}

/// The design runs the outer stop past the card's edge and a gradient stop must land inside 0..1,
/// so the last stop is the colour the gradient has actually reached by the edge.
LinearGradient _fill(SmileProductHue hue) => LinearGradient(
  colors: <Color>[_gradientStart(hue), _gradientEnd(hue)],
  stops: <double>[hue.stopStart, math.min(hue.stopEnd, 1)],
);

Color _gradientStart(SmileProductHue hue) =>
    hue.from.withValues(alpha: hue.fromAlpha);

Color _gradientEnd(SmileProductHue hue) {
  final Color start = _gradientStart(hue);
  final Color end = hue.to.withValues(alpha: hue.toAlpha);
  return hue.stopEnd > 1
      ? Color.lerp(
          start,
          end,
          (1 - hue.stopStart) / (hue.stopEnd - hue.stopStart),
        )!
      : end;
}

/// The ink that contrasts with a fill: one scrim across six cards this different leaves marks
/// invisible at both ends.
Color _inkOn(Color fill) => fill.computeLuminance() > _inkCrossover
    ? smileOffBlackLight
    : SmileColorLight.colorTextInverse;

/// 174x148 in the design's 2-up grid, built from the scale rather than pinned.
const double _cardMinHeight = SmileDimens.space64 * 2 + SmileDimens.space20;

/// The design's two fixed alphas.
const double _scrimAlpha = 0.16;
const double _ghostAlpha = 0.10;

/// The standard white-or-dark crossover: above it a fill carries dark ink, below it light.
const double _inkCrossover = 0.179;
