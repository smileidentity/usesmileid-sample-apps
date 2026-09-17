import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_glyphs.dart';

/// Reaches the token session from inside a form, where the nav bar's token affordance is not shown.
class UseSmileIDSampleFloatingTokenButton extends StatelessWidget {
  /// Takes only the action; its treatment matches the nav bar's token control, not a primary FAB.
  const UseSmileIDSampleFloatingTokenButton({required this.onTap, super.key});

  /// Opens the token session.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.tokenFloat,
      button: true,
      label: 'Token session',
      child: Material(
        // White with a border, like the nav bar's token control — not a primary-filled FAB.
        color: colors.surface,
        shape: CircleBorder(
          side: BorderSide(
            color: colors.cardStroke,
            width: SmileDimens.borderWidthThin,
          ),
        ),
        elevation: SmileDimens.space4,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            // 46 in the design; space48 here, which is also the platform touch-target minimum.
            width: SmileDimens.space48,
            height: SmileDimens.space48,
            child: Center(
              child: UseSmileIDSampleGlyphs.scanMark(colors.textTitle),
            ),
          ),
        ),
      ),
    );
  }
}
