import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// A snackbar: a dark bar with a message and an underlined action, spanning the width it is given.
///
/// Keeps the `sample_toast*` ids — the design node is named "toast", and renaming churns four apps.
class UseSmileIDSampleToast extends StatelessWidget {
  /// An action needs both halves; either one alone draws the message-only variant.
  const UseSmileIDSampleToast({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// The confirmation being reported.
  final String message;

  /// The action's label — "Undo" on a removal, "Make active" on a created profile.
  final String? actionLabel;

  /// What the action does; the offer is consumed on dismissal, so there is no second chance.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(context);
    final String? label = actionLabel;
    final VoidCallback? action = onAction;
    final bool hasAction = label != null && action != null;

    return Semantics(
      identifier: UseSmileIDSampleTestIds.toast,
      container: true,
      child: Container(
        // Spans the width it is given, between the 16 margins the design draws it inside.
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.textTitle,
          borderRadius: const BorderRadius.all(Radius.circular(SmileDimens.radiusMd)),
          boxShadow: const <BoxShadow>[SmileShadows.elevationFloating],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _barHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SmileDimens.spacingMd,
              vertical: _barPaddingY,
            ),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) => Wrap(
                spacing: SmileDimens.spacingSm,
                runSpacing: SmileDimens.space4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  // Bounded rather than flexible: Wrap gives a child unbounded width, so without
                  // this the message never wraps, and with it a long one pushes the action onto
                  // its own line whole instead of breaking the word in half.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Text(
                      message,
                      style: UseSmileIDSampleType.bannerTextFont.copyWith(
                        fontSize: _messageSize,
                        fontWeight: FontWeight.w500,
                        color: colors.background,
                      ),
                    ),
                  ),
                  if (hasAction) _action(colors, label, action),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widened, not squared off: a 48-high action inflates the 46 bar to 72, so the bar's own height
  /// is the vertical target and the minimum width carries the rest.
  Widget _action(UseSmileIDSampleColors colors, String label, VoidCallback action) => Semantics(
    identifier: UseSmileIDSampleTestIds.toastUndo,
    button: true,
    child: GestureDetector(
      onTap: action,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: SmileDimens.sizeControlMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SmileDimens.spacingXs),
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: false,
            style: UseSmileIDSampleType.linkFont.copyWith(
              fontSize: _actionSize,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: colors.background,
              color: colors.background,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The design's own bar height; no scale token carries 46, and 48 would inflate the bar to 72.
const double _barHeight = 46;

/// The design's vertical padding, which no scale token carries.
const double _barPaddingY = 13;

/// The message run, a half-point off the nearest token.
const double _messageSize = 13.5;

/// The action run.
const double _actionSize = 14;
