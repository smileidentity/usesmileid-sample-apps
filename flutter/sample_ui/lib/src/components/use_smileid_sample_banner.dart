import 'package:flutter/widgets.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';

/// The app's neutral banner, as the session-ended card draws it: an all-caps caption over the message.
class UseSmileIDSampleBanner extends StatelessWidget {
  /// [caption] over [message].
  const UseSmileIDSampleBanner({
    required this.caption,
    required this.message,
    this.testId,
    super.key,
  });

  /// What happened, drawn in capitals.
  final String caption;

  /// The failure's message.
  final String message;

  /// The banner's accessibility id.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: testId,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: UseSmileIDSampleShapes.card,
          border: Border.all(
            color: colors.cardStroke,
            width: smileCardStrokeWidth,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SmileDimens.space64),
          child: Padding(
            padding: const EdgeInsets.all(SmileDimens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  caption.toUpperCase(),
                  style: UseSmileIDSampleType.textStyleOverline.copyWith(
                    color: colors.textBody,
                  ),
                ),
                const SizedBox(height: SmileDimens.spacingXxs),
                Text(
                  message,
                  style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                    color: colors.textTitle,
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
