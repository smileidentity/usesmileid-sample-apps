import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_label_type.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';

/// The date separator in the verifications list; both halves arrive formatted, both being
/// locale-dependent, and a day with no relative word renders its absolute date alone.
class UseSmileIDSampleDateGroupHeader extends StatelessWidget {
  /// Takes the two halves already formatted, so the component holds no date string.
  const UseSmileIDSampleDateGroupHeader({
    required this.relative,
    required this.absolute,
    this.testId,
    super.key,
  });

  /// The relative word, empty when the day is older than yesterday.
  final String relative;

  /// The absolute date.
  final String absolute;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: testId,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: SmileDimens.spacingXs),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          // Two spaces either side of the dot, as the design sets it.
          relative.isEmpty ? absolute : '$relative  ·  $absolute',
          style: useSmileIDSampleLabelStyle(
            UseSmileIDSampleType.textStyleOverline,
          ).copyWith(color: UseSmileIDSampleTheme.colorsOf(context).textMuted),
        ),
      ),
    ),
  );
}
