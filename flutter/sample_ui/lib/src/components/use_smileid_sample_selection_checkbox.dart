import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// The select-mode checkbox: circular rather than a rounded square, which is the design's correction.
class UseSmileIDSampleSelectionCheckbox extends StatelessWidget {
  /// Takes the value rather than owning it, so the screen's selection set is the single truth.
  const UseSmileIDSampleSelectionCheckbox({
    required this.checked,
    required this.onChanged,
    this.testId,
    super.key,
  });

  /// Whether the row is selected.
  final bool checked;

  /// Called with the new value.
  final ValueChanged<bool> onChanged;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: testId,
      checked: checked,
      child: InkResponse(
        onTap: () => onChanged(!checked),
        radius: SmileDimens.sizeControlMd / 2,
        child: SizedBox(
          // The platform interactive minimum around a 24 control, not a 24 tap target.
          width: SmileDimens.sizeControlMd,
          height: SmileDimens.sizeControlMd,
          child: Center(
            child: Container(
              width: SmileDimens.sizeIconLg,
              height: SmileDimens.sizeIconLg,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? colors.primary : colors.surface,
                // A 2 ring in border-strong: color.border is far too pale to read as a control.
                border: Border.all(
                  width: SmileDimens.borderWidthThick,
                  color: checked ? colors.primary : smileBorderStrong,
                ),
              ),
              child: checked
                  ? UseSmileIDSampleGlyphs.check(
                      colors.onPrimary,
                      size: _checkSize,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The glyph inside a 24 ring; the icon scale's 16 leaves no ring visible.
const double _checkSize = 11;
