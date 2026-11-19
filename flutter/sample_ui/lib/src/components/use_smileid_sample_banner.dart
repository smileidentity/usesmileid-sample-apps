import 'package:flutter/widgets.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_icons.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_button.dart';
import 'use_smileid_sample_icon.dart';

/// Which accent a banner carries: warning for a failure the user can act on, error for one that is final.
enum UseSmileIDSampleBannerTone {
  /// The user can get past it.
  warning,

  /// Close is all it offers.
  error,
}

/// The design system's banner: a neutral surface with the tone's accent edge and glyph, a title over the message, and at most one action.
class UseSmileIDSampleBanner extends StatelessWidget {
  /// A button when [actionProminent], a trailing text action otherwise.
  const UseSmileIDSampleBanner({
    required this.title,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    this.actionProminent = true,
    this.testId,
    this.actionTestId,
    super.key,
  });

  /// The banner's headline.
  final String title;

  /// The failure's message.
  final String message;

  /// The accent the bar and glyph take.
  final UseSmileIDSampleBannerTone tone;

  /// The one action's label; null draws none.
  final String? actionLabel;

  /// What the action does.
  final VoidCallback? onAction;

  /// A full-width button when it moves the user on, a text action when it only closes.
  final bool actionProminent;

  /// The banner's accessibility id.
  final String? testId;

  /// The action's accessibility id.
  final String? actionTestId;

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
    final String? label = actionLabel;
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
                              if (label != null && actionProminent) ...<Widget>[
                                const SizedBox(height: SmileDimens.spacingMd),
                                UseSmileIDSampleButton(
                                  text: label,
                                  onPressed: onAction ?? () {},
                                  testId: actionTestId,
                                ),
                              ] else if (label != null)
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Semantics(
                                    identifier: actionTestId,
                                    button: true,
                                    child: GestureDetector(
                                      onTap: onAction,
                                      behavior: HitTestBehavior.opaque,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: SmileDimens.sizeControlMd,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: SmileDimens.spacingXs,
                                          ),
                                          child: Center(
                                            widthFactor: 1,
                                            child: Text(
                                              label,
                                              style: UseSmileIDSampleType
                                                  .linkFont
                                                  .copyWith(
                                                    color: colors.primary,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
