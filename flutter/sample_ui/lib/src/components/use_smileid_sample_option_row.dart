import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// One row in the country or ID-type picker; country rows lead with a flag.
class UseSmileIDSampleOptionRow extends StatelessWidget {
  /// [leadingText] is the flag emoji, which is text rather than an asset and so needs no icon set.
  const UseSmileIDSampleOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingText,
    this.testId,
    super.key,
  });

  /// The country or ID-type name.
  final String label;

  /// Whether this option is chosen.
  final bool selected;

  /// What a tap does.
  final VoidCallback onTap;

  /// The country's flag, absent on an ID-type row.
  final String? leadingText;

  /// The `sample_*` id the sheet supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: testId,
      selected: selected,
      child: Material(
        color: selected ? colors.surfaceTile : Colors.transparent,
        borderRadius: BorderRadius.circular(SmileDimens.radiusField),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SmileDimens.radiusField),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: SmileDimens.sizeControlMd,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingSm,
                vertical: SmileDimens.spacingXs,
              ),
              child: Row(
                children: <Widget>[
                  if (leadingText != null) ...<Widget>[
                    Text(
                      leadingText!,
                      style: UseSmileIDSampleType.textStyleBody.copyWith(
                        fontSize: _flagSize,
                      ),
                    ),
                    const SizedBox(width: SmileDimens.spacingSm),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                        fontSize: _optionLabelSize,
                        color: colors.textTitle,
                      ),
                    ),
                  ),
                  if (selected) ...<Widget>[
                    const SizedBox(width: SmileDimens.spacingSm),
                    SizedBox(
                      width: SmileDimens.sizeIconMd,
                      height: SmileDimens.sizeIconMd,
                      child: Center(
                        child: UseSmileIDSampleGlyphs.check(colors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The flag emoji's run, which grows with the font scale.
const double _flagSize = 19;

/// Body Strong at its real 14.
const double _optionLabelSize = 14;
