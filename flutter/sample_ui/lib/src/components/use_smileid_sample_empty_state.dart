import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';

/// What a list says when it has nothing to show. Not in the design — the app's own convention,
/// muted and centred, because an empty list is a normal state rather than a failure.
class UseSmileIDSampleEmptyState extends StatelessWidget {
  /// [supportingText] only where the reader can act on it; a search that matched nothing cannot.
  const UseSmileIDSampleEmptyState({
    required this.text,
    this.supportingText,
    this.testId,
    super.key,
  });

  /// The line that says what is missing.
  final String text;

  /// The line that says what to do about it, where there is something to do.
  final String? supportingText;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: testId,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SmileDimens.spacingMd,
          vertical: SmileDimens.space32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              text,
              textAlign: TextAlign.center,
              style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                color: colors.textBody,
              ),
            ),
            if (supportingText != null) ...<Widget>[
              const SizedBox(height: SmileDimens.spacingXxs),
              Text(
                supportingText!,
                textAlign: TextAlign.center,
                style: UseSmileIDSampleType.textStyleCaption.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
