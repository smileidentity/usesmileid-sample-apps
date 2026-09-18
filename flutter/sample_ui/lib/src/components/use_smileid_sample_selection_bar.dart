import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_glyphs.dart';

/// Replaces the nav bar in select mode, full-bleed at the bottom with a top edge only.
class UseSmileIDSampleSelectionBar extends StatelessWidget {
  /// The count is its own node, so a flow asserts equality rather than parsing prose.
  const UseSmileIDSampleSelectionBar({
    required this.selectedCount,
    required this.onRemove,
    super.key,
  });

  /// How many rows are selected.
  final int selectedCount;

  /// Hides the selected rows from this app's list.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.selectionBar,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          // A top edge only; a full border would outline all four sides of a full-bleed bar.
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: SmileDimens.borderWidthHairline,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: SmileDimens.spacingMd,
            right: SmileDimens.spacingMd,
            top: SmileDimens.spacingSm,
            bottom:
                SmileDimens.spacingSm +
                MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Wrap(
            spacing: SmileDimens.spacingSm,
            runSpacing: SmileDimens.spacingXs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Semantics(
                    identifier: UseSmileIDSampleTestIds.selectionCount,
                    child: Text(
                      '$selectedCount selected',
                      style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                        fontSize: _countSize,
                        fontWeight: FontWeight.w700,
                        color: colors.textTitle,
                      ),
                    ),
                  ),
                  const SizedBox(height: SmileDimens.spacingXxs),
                  Text(
                    selectedCount == 0
                        ? 'Tap rows to select'
                        : 'Tap Hide from List to confirm',
                    style: UseSmileIDSampleType.textStyleBodySm.copyWith(
                      fontSize: _hintSize,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              _RemoveAction(
                enabled: selectedCount > 0,
                onRemove: onRemove,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The soft error pair, dimmed rather than recoloured when disabled, so it still reads as the
/// strong action.
class _RemoveAction extends StatelessWidget {
  const _RemoveAction({
    required this.enabled,
    required this.onRemove,
    required this.colors,
  });

  final bool enabled;
  final VoidCallback onRemove;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: UseSmileIDSampleTestIds.selectionRemove,
    button: true,
    enabled: enabled,
    child: Opacity(
      opacity: enabled ? 1 : _disabledOpacity,
      child: Material(
        color: colors.badge.errorBackground,
        borderRadius: UseSmileIDSampleShapes.pill,
        child: InkWell(
          onTap: enabled ? onRemove : null,
          borderRadius: UseSmileIDSampleShapes.pill,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: SmileDimens.space40),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
                vertical: SmileDimens.spacingXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UseSmileIDSampleGlyphs.trash(
                    colors.badge.errorText,
                    size: SmileDimens.sizeIconSm,
                  ),
                  const SizedBox(width: SmileDimens.spacingXs),
                  Text(
                    'Hide from List',
                    style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                      fontSize: _removeSize,
                      fontWeight: FontWeight.w700,
                      color: colors.badge.errorText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The bar's three runs, none of which a type token matches.
const double _countSize = 14;
const double _hintSize = 11.5;
const double _removeSize = 13.5;

/// Dimmed, not recoloured: a recoloured action stops reading as the strong one.
const double _disabledOpacity = 0.45;
