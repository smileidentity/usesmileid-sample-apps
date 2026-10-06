import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';

/// What a list says when it has nothing to show. Not in the design — the app's own convention,
/// muted and centred, because an empty list is a normal state rather than a failure.
class UseSmileIDSampleEmptyState extends StatelessWidget {
  /// [supportingText] only where the reader can act on it; a search that matched nothing cannot.
  const UseSmileIDSampleEmptyState({
    required this.text,
    this.supportingText,
    this.testId,
    this.onRetry,
    this.retryTestId,
    super.key,
  });

  /// The line that says what is missing.
  final String text;

  /// The line that says what to do about it, where there is something to do.
  final String? supportingText;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  /// Only for a list that failed to load: retrying can change that answer, and nothing else here can.
  final VoidCallback? onRetry;

  /// The Retry action's own id.
  final String? retryTestId;

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
            if (onRetry != null)
              Semantics(
                identifier: retryTestId,
                button: true,
                child: TextButton(
                  onPressed: onRetry,
                  child: Text(
                    context.strings.commonRetry,
                    style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                      color: colors.textLink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
