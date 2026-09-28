import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_button.dart';

/// The sample's own continue button, drawn by the SDK in its continue slots while Custom continue is on.
class UseSmileIDSampleCustomContinueButton extends StatelessWidget {
  /// [onPressed] and [enabled] are the slot scope's, so the SDK keeps deciding what the tap does.
  const UseSmileIDSampleCustomContinueButton({
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  /// The slot's action.
  final VoidCallback onPressed;

  /// Whether the slot allows the tap.
  final bool enabled;

  @override
  Widget build(BuildContext context) => UseSmileIDSampleButton(
    text: useSmileIDSampleCustomContinueLabel,
    onPressed: onPressed,
    enabled: enabled,
    testId: UseSmileIDSampleTestIds.customContinue,
  );
}

/// The sample's own cancel button, for the SDK's cancel slots: the continue button's outlined twin.
class UseSmileIDSampleCustomCancelButton extends StatelessWidget {
  /// [onPressed] and [enabled] are the slot scope's, as the continue button's are.
  const UseSmileIDSampleCustomCancelButton({
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  /// The slot's action.
  final VoidCallback onPressed;

  /// Whether the slot allows the tap.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final Color foreground = enabled
        ? colors.button.primaryBackground
        : colors.button.disabledText;
    final Color border = enabled
        ? colors.button.primaryBackground
        : colors.button.disabledBackground;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: enabled,
        identifier: UseSmileIDSampleTestIds.customCancel,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: UseSmileIDSampleShapes.pill,
            side: BorderSide(color: border, width: SmileDimens.borderWidthThin),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: UseSmileIDSampleShapes.pill,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: SmileDimens.sizeControlLg,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SmileDimens.spacingLg,
                  vertical: SmileDimens.space4,
                ),
                child: Center(
                  child: Text(
                    useSmileIDSampleCustomCancelLabel,
                    textAlign: TextAlign.center,
                    style: UseSmileIDSampleType.buttonFont.copyWith(
                      color: foreground,
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

/// The continue button's label, which names it for a demo audience.
const String useSmileIDSampleCustomContinueLabel = 'Custom continue';

/// The cancel button's label.
const String useSmileIDSampleCustomCancelLabel = 'Custom cancel';
