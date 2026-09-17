import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';

/// The full-width primary action; a minimum height so the label wraps rather than clips, and
/// loading refuses taps while keeping the enabled colours.
class UseSmileIDSampleButton extends StatelessWidget {
  /// [loading] outranks [enabled]: a button mid-submission is not a disabled button.
  const UseSmileIDSampleButton({
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.testId,
    super.key,
  });

  /// The label.
  final String text;

  /// What a tap does; never called while loading or disabled.
  final VoidCallback onPressed;

  /// Whether the action is available.
  final bool enabled;

  /// Whether a submission is in flight.
  final bool loading;

  /// The `sample_*` id the screen supplies, since most ids are assigned per screen.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(context);
    final bool tappable = enabled && !loading;
    final Color background = tappable || loading
        ? colors.button.primaryBackground
        : colors.button.disabledBackground;
    final Color foreground = tappable || loading
        ? colors.button.primaryText
        : colors.button.disabledText;

    final Widget button = Semantics(
      button: true,
      enabled: tappable,
      identifier: testId,
      child: Material(
        color: background,
        borderRadius: UseSmileIDSampleShapes.pill,
        child: InkWell(
          onTap: tappable ? onPressed : null,
          borderRadius: UseSmileIDSampleShapes.pill,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SmileDimens.sizeControlLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingLg,
                vertical: SmileDimens.space4,
              ),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: SmileDimens.sizeIconMd,
                        height: SmileDimens.sizeIconMd,
                        child: CircularProgressIndicator(
                          strokeWidth: SmileDimens.borderWidthThick,
                          valueColor: AlwaysStoppedAnimation<Color>(foreground),
                        ),
                      )
                    : Text(
                        text,
                        textAlign: TextAlign.center,
                        style: UseSmileIDSampleType.buttonFont.copyWith(color: foreground),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
    return SizedBox(width: double.infinity, child: button);
  }
}
