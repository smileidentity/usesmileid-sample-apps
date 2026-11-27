import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_label_type.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_selection_blend.dart';

/// A status filter with its live count, the count a node of its own because it is what a delete
/// is asserted on — "the count dropped" proves the delete, not the toast.
class UseSmileIDSampleFilterChip extends StatelessWidget {
  /// Takes [count] as a number so the caller cannot format it into prose.
  const UseSmileIDSampleFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.testId,
    this.countTestId,
    super.key,
  });

  /// The status name.
  final String label;

  /// How many rows the filter matches.
  /// Null for a chip that picks a value rather than filtering a list, which has nothing to count.
  final int? count;

  /// Whether this chip is the active filter.
  final bool selected;

  /// What a tap does.
  final VoidCallback onTap;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  /// The `sample_*` id for the count, asserted on separately.
  final String? countTestId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // The pill stays the design's size; the platform minimum is added around it and taps too.
    return Semantics(
      identifier: testId,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: useSmileIDSampleTapTarget(context),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: UseSmileIDSampleSelectionBlend(
              selected: selected,
              builder: (BuildContext context, double picked) =>
                  _pill(colors, picked),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(UseSmileIDSampleColors colors, double picked) => Material(
    color: Color.lerp(colors.filterChip.background, colors.primary, picked),
    // A stadium, not a 999 radius: radius.chip is the design's way of saying fully rounded.
    shape: StadiumBorder(
      side: BorderSide(
        color: Color.lerp(
          colors.cardStroke,
          colors.cardStroke.withAlpha(0),
          picked,
        )!,
        width: smileCardStrokeWidth,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: SmileDimens.space32),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SmileDimens.spacingSm,
            vertical: SmileDimens.spacingXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: UseSmileIDSampleType.filterChipFont.copyWith(
                  fontSize: _labelSize,
                  fontWeight: FontWeight.w700,
                  color: Color.lerp(
                    colors.filterChip.label,
                    colors.onPrimary,
                    picked,
                  ),
                ),
              ),
              if (count != null) const SizedBox(width: SmileDimens.spacingXxs),
              if (count != null)
                Semantics(
                  identifier: countTestId,
                  child: Text(
                    '$count',
                    style:
                        useSmileIDSampleLabelStyle(
                          UseSmileIDSampleType.textStyleOverline,
                          // The design file's muted grey, deliberately not filter-chip.value's blue.
                        ).copyWith(
                          color: Color.lerp(
                            colors.textMuted,
                            colors.onPrimary,
                            picked,
                          ),
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

/// The chip's label run, which the generated filter-chip font does not match.
const double _labelSize = 12.5;
