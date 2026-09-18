import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';

/// Initials in a rounded square, or a placeholder without them.
class UseSmileIDSampleAvatar extends StatelessWidget {
  /// [size] is the component's own default; a parent whose spec names a different metric passes it.
  const UseSmileIDSampleAvatar({
    required this.initials,
    this.size = SmileDimens.space40,
    this.containerColor,
    super.key,
  });

  /// The initials to draw; blank draws the placeholder instead.
  final String initials;

  /// The square's side before text scaling.
  final double size;

  /// The per-profile fill; the first hue when the caller has no profile to colour by.
  final Color? containerColor;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final bool hasInitials = initials.trim().isNotEmpty;
    // The square grows with text, because wrapping the initials renders an ellipse at 2x.
    final double side = MediaQuery.textScalerOf(context).scale(size);
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasInitials
            ? (containerColor ?? smileProfileHues.first)
            : colors.avatar.placeholderBackground,
        borderRadius: UseSmileIDSampleShapes.avatar,
      ),
      child: Text(
        hasInitials ? initials : '?',
        textAlign: TextAlign.center,
        style: UseSmileIDSampleType.avatarFont.copyWith(
          color: hasInitials
              ? colors.avatar.text
              : colors.avatar.placeholderIcon,
        ),
      ),
    );
  }
}

/// The avatar fill for a profile at [profileIndex], cycled by list position.
Color avatarColorForProfile(int profileIndex) =>
    smileProfileHues[(profileIndex < 0 ? 0 : profileIndex) %
        smileProfileHues.length];
