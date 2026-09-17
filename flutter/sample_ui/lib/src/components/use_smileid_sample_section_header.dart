import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';

/// Sentence-case headings, distinct from the all-caps section label.
class UseSmileIDSampleSectionHeader extends StatelessWidget {
  /// Takes the text already cased; the products board draws these in sentence case.
  const UseSmileIDSampleSectionHeader({
    required this.text,
    this.testId,
    super.key,
  });

  /// The heading.
  final String text;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: testId,
    header: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: SmileDimens.spacingXs),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          style: UseSmileIDSampleType.textStyleHeadingSection.copyWith(
            fontSize: smileSectionHeaderSize,
            height: smileSectionHeaderLineHeight / smileSectionHeaderSize,
            fontWeight: FontWeight.values[smileSectionHeaderWeight ~/ 100 - 1],
            color: UseSmileIDSampleTheme.colorsOf(context).foreground,
          ),
        ),
      ),
    ),
  );
}
