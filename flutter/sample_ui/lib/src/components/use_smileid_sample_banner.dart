import 'package:flutter/widgets.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_icons.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_icon.dart';

/// Which accent a banner carries: warning for a failure trying again later can get past, error for one it can't.
enum UseSmileIDSampleBannerTone {
  /// Trying again later can get past it.
  warning,

  /// Trying again won't get past it.
  error,
}

/// The design system's banner: a neutral surface with the tone's accent edge and glyph, and a title over the message.
class UseSmileIDSampleBanner extends StatelessWidget {
  /// [title] over [message], in [tone].
  const UseSmileIDSampleBanner({
    required this.title,
    required this.message,
    required this.tone,
    this.testId,
    super.key,
  });

  /// The banner's headline.
  final String title;

  /// The failure's message.
  final String message;

  /// The accent the bar and glyph take.
  final UseSmileIDSampleBannerTone tone;

  /// The banner's accessibility id.
  final String? testId;

  /// The banner contract's leading edge.
  static const double _accentWidth = 3;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final Color accent = switch (tone) {
      UseSmileIDSampleBannerTone.warning => colors.banner.warningAccent,
      UseSmileIDSampleBannerTone.error => colors.banner.errorAccent,
    };
    return Semantics(
      identifier: testId,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.banner.background,
          // The card stroke, as the session-ended banner takes: banner.border carries one light value in both schemes.
          borderRadius: UseSmileIDSampleShapes.field,
          border: Border.all(
            color: colors.cardStroke,
            width: smileCardStrokeWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: UseSmileIDSampleShapes.field,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ColoredBox(
                  color: accent,
                  child: const SizedBox(width: _accentWidth),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(SmileDimens.spacingMd),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        UseSmileIDSampleIcon(
                          asset: tone == UseSmileIDSampleBannerTone.warning
                              ? SmileIcons.materialWarning
                              : SmileIcons.materialCancel,
                          tint: accent,
                        ),
                        const SizedBox(width: SmileDimens.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                title,
                                style: UseSmileIDSampleType.textStyleBodyStrong
                                    .copyWith(color: colors.banner.title),
                              ),
                              const SizedBox(height: SmileDimens.spacingXxs),
                              Text(
                                message,
                                style: UseSmileIDSampleType.textStyleBodySm
                                    .copyWith(color: colors.banner.text),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
