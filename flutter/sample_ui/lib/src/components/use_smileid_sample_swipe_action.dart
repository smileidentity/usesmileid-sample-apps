import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// Wraps a row in the platform swipe gesture; the design fixes only the revealed treatment.
class UseSmileIDSampleSwipeAction extends StatelessWidget {
  /// [dismissKey] is the row's own identity, which the platform needs to animate one row out.
  const UseSmileIDSampleSwipeAction({
    required this.dismissKey,
    required this.onRemove,
    required this.child,
    super.key,
  });

  /// The row's identity, distinct per row.
  final Key dismissKey;

  /// Hides the row; called once, on the settled gesture.
  final VoidCallback onRemove;

  /// The row itself.
  final Widget child;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: dismissKey,
    // End to start only, as the design draws it; velocity, threshold and settle stay the platform's.
    direction: DismissDirection.endToStart,
    // Fires on the settled gesture, so a rebuild mid-swipe cannot remove the row twice.
    onDismissed: (DismissDirection direction) => onRemove(),
    background: const SizedBox.shrink(),
    secondaryBackground: const _RemoveBackdrop(),
    child: child,
  );
}

class _RemoveBackdrop extends StatelessWidget {
  const _RemoveBackdrop();

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: _revealWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SmileDimens.spacingXs,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UseSmileIDSampleGlyphs.trash(colors.errorFill),
              const SizedBox(height: SmileDimens.spacingXxs),
              Text(
                'Hide',
                style: UseSmileIDSampleType.textStyleCaption.copyWith(
                  color: colors.errorFill,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 80 in the design; space64 plus a gap is the nearest the scale reaches.
const double _revealWidth = SmileDimens.space64 + SmileDimens.spacingMd;
