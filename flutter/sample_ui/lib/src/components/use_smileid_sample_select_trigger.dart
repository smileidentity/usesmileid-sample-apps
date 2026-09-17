import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// The design leads each trigger with an emoji rather than a glyph, so it carries no tint.
class UseSmileIDSampleTriggerEmoji extends StatelessWidget {
  /// Takes the emoji; the chosen country's flag, or a globe as placeholder.
  const UseSmileIDSampleTriggerEmoji({required this.emoji, super.key});

  /// The emoji to draw.
  final String emoji;

  @override
  Widget build(BuildContext context) => Text(
    emoji,
    style: UseSmileIDSampleType.inputFont.copyWith(fontSize: _emojiSize),
  );
}

/// Looks like an input, behaves like a button.
///
/// Disabled is load-bearing: the ID-type trigger stays greyed until a country is chosen.
class UseSmileIDSampleSelectTrigger extends StatelessWidget {
  /// A null [value] draws [placeholder] in the placeholder colour.
  const UseSmileIDSampleSelectTrigger({
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.enabled = true,
    this.leading,
    this.testId,
    super.key,
  });

  /// The chosen value, null until one is chosen.
  final String? value;

  /// Shown while nothing is chosen.
  final String placeholder;

  /// What a tap does.
  final VoidCallback onTap;

  /// Whether the trigger can be tapped.
  final bool enabled;

  /// The leading emoji or glyph, handed the content colour.
  final Widget Function(Color tint)? leading;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // The disabled pair, not muted text on an almost-white surface, which does not read as disabled.
    final Color content = !enabled
        ? colors.button.disabledText
        : value != null
        ? colors.textTitle
        : colors.input.placeholder;
    return Semantics(
      identifier: testId,
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled
            ? colors.input.background
            : colors.button.disabledBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmileDimens.radiusField),
          // Outlined in PRIMARY when actionable, which is what says it can be tapped.
          side: BorderSide(
            color: enabled ? colors.primary : colors.input.border,
            width: SmileDimens.borderWidthThin,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(SmileDimens.radiusField),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: SmileDimens.sizeControlMd,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
                vertical: SmileDimens.spacingSm,
              ),
              child: Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    // A minimum, not a fixed box: an emoji grows with the font scale and clips.
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: SmileDimens.sizeIconMd,
                        minHeight: SmileDimens.sizeIconMd,
                      ),
                      child: Center(child: leading!(content)),
                    ),
                    const SizedBox(width: SmileDimens.spacingXs),
                  ],
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      style: UseSmileIDSampleType.inputFont.copyWith(
                        fontSize: _triggerTextSize,
                        fontWeight: FontWeight.w600,
                        color: content,
                      ),
                    ),
                  ),
                  const SizedBox(width: SmileDimens.spacingXs),
                  UseSmileIDSampleGlyphs.chevronDown(
                    content,
                    size: _chevronSize,
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

/// The trigger's label run.
const double _triggerTextSize = 15;

/// The leading emoji's run.
const double _emojiSize = 18;

/// The DOWN chevron; the list chevron is larger and points right.
const double _chevronSize = 12;
