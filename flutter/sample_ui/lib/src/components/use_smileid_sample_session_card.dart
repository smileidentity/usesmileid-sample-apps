import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// The active token session and its m:ss countdown.
///
/// [remaining] arrives formatted, because the deadline is absolute and the ticking is the screen's.
/// Both gradient stops are translucent, so the card composites against the page and reads
/// differently per scheme by design.
class UseSmileIDSampleSessionCard extends StatelessWidget {
  /// Takes the formatted countdown rather than a duration, so no component holds a clock.
  const UseSmileIDSampleSessionCard({
    required this.sessionId,
    required this.remaining,
    super.key,
  });

  /// The linked session's id.
  final String sessionId;

  /// The countdown, already formatted as m:ss.
  final String remaining;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // The gradient is scheme-independent, so its ink is too: color.surface is #272A35 in dark.
    final Color ink = SmileColorLight.colorTextInverse;
    return Semantics(
      identifier: UseSmileIDSampleTestIds.sessionCard,
      container: true,
      child: _SessionSurface(
        decoration: BoxDecoration(
          borderRadius: UseSmileIDSampleShapes.card,
          gradient: LinearGradient(colors: _sessionGradient),
          border: Border.all(
            color: colors.cardStroke,
            width: smileCardStrokeWidth,
          ),
        ),
        lead: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'ACTIVE TOKEN SESSION',
              style: UseSmileIDSampleType.textStyleOverline.copyWith(
                letterSpacing: _labelTracking,
                color: ink,
              ),
            ),
            const SizedBox(height: SmileDimens.spacingXxs),
            Text(
              'Linked to session $sessionId',
              style: UseSmileIDSampleType.textStyleCaption.copyWith(
                fontWeight: FontWeight.values[smileCardFamilyWeight ~/ 100 - 1],
                color: ink,
              ),
            ),
          ],
        ),
        trail: Semantics(
          identifier: UseSmileIDSampleTestIds.sessionCountdown,
          child: Text(
            remaining,
            // The one value on this card that must stay whole; the text beside it yields.
            softWrap: false,
            style: UseSmileIDSampleType.textStyleHeadingCard.copyWith(
              fontSize: _countdownSize,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Replaces the session card on expiry: a neutral card, not a warning-accented one.
class UseSmileIDSampleSessionEndedBanner extends StatelessWidget {
  /// Matches the session card's height, so the two swap without the layout moving.
  const UseSmileIDSampleSessionEndedBanner({required this.onScan, super.key});

  /// Reaches the scan screen to relink.
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.sessionEndedBanner,
      container: true,
      child: _SessionSurface(
        decoration: BoxDecoration(
          borderRadius: UseSmileIDSampleShapes.card,
          // surface-muted per this component's token list; the banner fill is a warm sand.
          color: colors.surfaceMuted,
          border: Border.all(
            color: colors.cardStroke,
            width: smileCardStrokeWidth,
          ),
        ),
        lead: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'TOKEN SESSION ENDED',
              style: UseSmileIDSampleType.textStyleOverline.copyWith(
                color: colors.banner.text,
              ),
            ),
            const SizedBox(height: SmileDimens.spacingXxs),
            Text(
              'Scan a token to relink',
              style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                color: colors.banner.title,
              ),
            ),
          ],
        ),
        trail: Semantics(
          button: true,
          child: GestureDetector(
            onTap: onScan,
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: SmileDimens.sizeControlMd,
                minHeight: SmileDimens.sizeControlMd,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SmileDimens.spacingXs,
                ),
                child: Center(
                  child: Text(
                    'Scan',
                    softWrap: false,
                    style: UseSmileIDSampleType.linkFont.copyWith(
                      color: colors.primary,
                    ),
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

/// The shape both cards take, so the two swap without the layout moving.
///
/// A flexible leading column rather than a wrap: the trailing half keeps its intrinsic width and
/// the text beside it wraps, so the card grows instead of the action moving under the text. A wrap
/// would need to be told what the trailing half costs, and guessed that wrong on both cards.
class _SessionSurface extends StatelessWidget {
  const _SessionSurface({
    required this.decoration,
    required this.lead,
    required this.trail,
  });

  final BoxDecoration decoration;
  final Widget lead;
  final Widget trail;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: decoration,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SmileDimens.space64),
      child: Padding(
        padding: const EdgeInsets.all(SmileDimens.spacingMd),
        child: Row(
          children: <Widget>[
            Expanded(child: lead),
            const SizedBox(width: SmileDimens.spacingSm),
            trail,
          ],
        ),
      ),
    ),
  );
}

/// Alpha is applied here, never baked into the token's hex.
final List<Color> _sessionGradient = <Color>[
  for (int index = 0; index < smileTokenSessionGradient.length; index++)
    smileTokenSessionGradient[index].withValues(
      alpha: smileTokenSessionGradientAlpha[index],
    ),
];

/// The overline's own tracking on this card, which the label style does not carry.
const double _labelTracking = 1;

/// The countdown's run.
const double _countdownSize = 24;
