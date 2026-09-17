import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// Which of the three treatments an app-bar control takes.
enum UseSmileIDSampleTopAppBarEmphasis {
  /// The dark control used for back and Scan token's torch.
  filled,

  /// The light trailing action.
  tonal,

  /// The soft-red delete.
  destructive,
}

/// The pushed-screen app bar: a dark-filled circular back control, a title, and an optional action.
///
/// The system back gesture stays the platform's regardless of this visual.
class UseSmileIDSampleTopAppBar extends StatelessWidget {
  /// [action] is optional, but its 40 slot is reserved either way so the title cannot shift.
  const UseSmileIDSampleTopAppBar({
    required this.title,
    required this.onBack,
    this.backSemanticLabel = 'Back',
    this.action,
    this.testId,
    super.key,
  });

  /// The screen's title.
  final String title;

  /// What the back control does; the platform gesture calls the same thing.
  final VoidCallback onBack;

  /// The back control's accessibility label.
  final String backSemanticLabel;

  /// The trailing control, where the screen has one.
  final Widget? action;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // A fixed row height, so a longer title cannot grow the bar and drop the header on one screen.
    final double scale = MediaQuery.textScalerOf(
      context,
    ).scale(_headerRowHeight);
    return Semantics(
      identifier: testId,
      header: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.viewPaddingOf(context).top,
          left: SmileDimens.spacingMd,
          right: SmileDimens.spacingMd,
          bottom: SmileDimens.spacingXs,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: scale),
          child: Row(
            children: <Widget>[
              UseSmileIDSampleTopAppBarButton(
                semanticLabel: backSemanticLabel,
                onTap: onBack,
                emphasis: UseSmileIDSampleTopAppBarEmphasis.filled,
                glyph: UseSmileIDSampleGlyphs.arrowBack,
              ),
              const SizedBox(width: SmileDimens.spacingXs),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  // Wraps rather than caps: ellipsising a title is the clipping the predicate forbids.
                  style: UseSmileIDSampleType.textStyleTitle.copyWith(
                    fontSize: _titleSize,
                    color: colors.textTitle,
                  ),
                ),
              ),
              const SizedBox(width: SmileDimens.spacingXs),
              // Holds the action's width even with none, so the title sits identically either way.
              action ??
                  const SizedBox(
                    width: SmileDimens.space40,
                    height: SmileDimens.space40,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One circular 40 app-bar control, its touch target expanded to the platform minimum.
class UseSmileIDSampleTopAppBarButton extends StatelessWidget {
  /// [glyph] is handed the tint its emphasis resolves to, so no caller picks a colour.
  const UseSmileIDSampleTopAppBarButton({
    required this.semanticLabel,
    required this.onTap,
    required this.glyph,
    this.emphasis = UseSmileIDSampleTopAppBarEmphasis.tonal,
    this.testId,
    super.key,
  });

  /// What the control does, spoken.
  final String semanticLabel;

  /// What a tap does.
  final VoidCallback onTap;

  /// Draws the mark in the tint its emphasis resolves to.
  final Widget Function(Color tint) glyph;

  /// Which treatment to take.
  final UseSmileIDSampleTopAppBarEmphasis emphasis;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final (Color container, Color tint) = switch (emphasis) {
      UseSmileIDSampleTopAppBarEmphasis.filled => (
        colors.textTitle,
        colors.textInverse,
      ),
      UseSmileIDSampleTopAppBarEmphasis.tonal => (
        colors.surfaceTile,
        colors.textTitle,
      ),
      UseSmileIDSampleTopAppBarEmphasis.destructive => (
        colors.badge.errorBackground,
        colors.badge.errorText,
      ),
    };
    return Semantics(
      identifier: testId,
      button: true,
      label: semanticLabel,
      child: Material(
        color: container,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: SmileDimens.space40,
            height: SmileDimens.space40,
            child: Center(child: glyph(tint)),
          ),
        ),
      ),
    );
  }
}

/// The design's centred title run.
const double _titleSize = 15;

/// Pinned, not a minimum: a minimum let a longer title grow the bar on one screen and not another.
const double _headerRowHeight = 40;
