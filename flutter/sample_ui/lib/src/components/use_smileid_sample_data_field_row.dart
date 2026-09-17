import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// A label/value pair on the verification-details card, optionally with a copy control.
class UseSmileIDSampleDataFieldRow extends StatelessWidget {
  /// [valueColor] is set only where the design colours the value, as the Status row's code is.
  const UseSmileIDSampleDataFieldRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.valueColor,
    this.testId,
    this.copyTestId,
    super.key,
  });

  /// The field name.
  final String label;

  /// The field value, already formatted — the data layer stores the code, not "200 OK".
  final String value;

  /// Copies the value; absent on rows the design gives no copy control.
  final VoidCallback? onCopy;

  /// Overrides the value's colour where the design colours it.
  final Color? valueColor;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  /// The `sample_*` id for the copy control.
  final String? copyTestId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: testId,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SmileDimens.space40),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SmileDimens.spacingMd,
            vertical: SmileDimens.spacingSm,
          ),
          // The spec's wrapping rule, which the Compose twin does not yet follow.
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => Wrap(
              spacing: SmileDimens.spacingXs,
              runSpacing: SmileDimens.spacingXxs,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  style: UseSmileIDSampleType.dataFieldLabelFont.copyWith(
                    fontSize: _fieldTextSize,
                    color: colors.dataField.label,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ConstrainedBox(
                      // The copy control's own width comes out of the value's column, or a value
                      // that fills the line pushes the control off the right edge.
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - _copyReserve(onCopy),
                      ),
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: UseSmileIDSampleType.dataFieldValueFont.copyWith(
                          fontSize: _fieldTextSize,
                          fontWeight: valueColor == null
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: valueColor ?? colors.dataField.value,
                        ),
                      ),
                    ),
                    if (onCopy != null) ...<Widget>[
                      const SizedBox(width: SmileDimens.spacingXs),
                      _CopyButton(
                        label: label,
                        onCopy: onCopy!,
                        testId: copyTestId,
                        colors: colors,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.label,
    required this.onCopy,
    required this.colors,
    this.testId,
  });

  final String label;
  final VoidCallback onCopy;
  final UseSmileIDSampleColors colors;
  final String? testId;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: testId,
    button: true,
    label: 'Copy $label',
    child: Material(
      color: colors.surfaceTile,
      borderRadius: BorderRadius.circular(SmileDimens.radiusSm),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(SmileDimens.radiusSm),
        child: SizedBox(
          width: SmileDimens.sizeIconLg,
          height: SmileDimens.sizeIconLg,
          child: Center(child: UseSmileIDSampleGlyphs.copy(colors.textMuted)),
        ),
      ),
    ),
  );
}

/// What the copy control occupies, so the value's column can leave room for it.
double _copyReserve(VoidCallback? onCopy) =>
    onCopy == null ? 0 : SmileDimens.sizeIconLg + SmileDimens.spacingXs;

/// Label and value alike; no type token carries 13.
const double _fieldTextSize = 13;
