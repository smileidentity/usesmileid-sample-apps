import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_label_type.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';

/// The all-caps group heading above a section. Callers pass the text already cased, so no locale
/// upper-casing can turn a Turkish i into something the design never drew.
class UseSmileIDSampleSectionLabel extends StatelessWidget {
  /// Takes the text as it should render.
  const UseSmileIDSampleSectionLabel({required this.text, this.testId, super.key});

  /// The heading, already cased.
  final String text;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: testId,
    child: Text(
      text,
      style: useSmileIDSampleLabelStyle(
        UseSmileIDSampleType.textStyleOverline,
      ).copyWith(color: UseSmileIDSampleTheme.colorsOf(context).textMuted),
    ),
  );
}
