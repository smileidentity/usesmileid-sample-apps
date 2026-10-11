import 'package:flutter/material.dart';

import '../model/use_smileid_sample_status.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_label_type.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';

/// A status pill in the design's soft tinted treatment, generated from one spec entry rather than
/// the design system's saturated `badge.*` pairs.
class UseSmileIDSampleStatusBadge extends StatelessWidget {
  /// Takes the status, not a colour pair: four platforms must map the four statuses identically.
  const UseSmileIDSampleStatusBadge({
    required this.status,
    this.testId,
    super.key,
  });

  /// Which of the four statuses to draw.
  final UseSmileIDSampleStatus status;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleBadgeTokens badge = UseSmileIDSampleTheme.colorsOf(
      context,
    ).badge;
    final (Color background, Color foreground) = switch (status) {
      UseSmileIDSampleStatus.clear => (
        badge.successBackground,
        badge.successText,
      ),
      UseSmileIDSampleStatus.attention => (
        badge.warningBackground,
        badge.warningText,
      ),
      UseSmileIDSampleStatus.blocked => (
        badge.errorBackground,
        badge.errorText,
      ),
      UseSmileIDSampleStatus.error => (
        badge.neutralBackground,
        badge.neutralText,
      ),
      UseSmileIDSampleStatus.processing => (
        badge.infoBackground,
        badge.infoText,
      ),
    };
    return Semantics(
      identifier: testId,
      child: UseSmileIDSamplePill(
        label: status.label(context.strings),
        background: background,
        foreground: foreground,
      ),
    );
  }
}

/// The soft pill every badge draws.
class UseSmileIDSamplePill extends StatelessWidget {
  /// Draws [label] on [background] in [foreground].
  const UseSmileIDSamplePill({
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
  });

  /// The already-cased text.
  final String label;

  /// The soft fill.
  final Color background;

  /// The text colour.
  final Color foreground;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      // radius.control, not radius.chip — the one metric a port reliably gets wrong here.
      borderRadius: UseSmileIDSampleShapes.pill,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SmileDimens.spacingXs,
        vertical: SmileDimens.space4,
      ),
      child: Text(
        label,
        style: useSmileIDSampleLabelStyle(
          UseSmileIDSampleType.textStyleOverline,
        ).copyWith(color: foreground),
      ),
    ),
  );
}
