import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';
import 'use_smileid_sample_top_app_bar.dart';

/// The partial sheet: a grab handle over a scrim, sized to its content.
Future<T?> showUseSmileIDSampleSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  String? testId,
}) {
  final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    // Content height, not the platform's half-screen state: at half, the five-field new-profile
    // sheet clipped its last field and put its CTA below the fold.
    isScrollControlled: true,
    useSafeArea: true,
    // The ROOT navigator: in the shell's body the bar is painted over the sheet and eats its taps.
    useRootNavigator: true,
    backgroundColor: colors.surface,
    barrierColor: colors.overlayScrim,
    shape: RoundedRectangleBorder(borderRadius: UseSmileIDSampleShapes.sheet),
    builder: (BuildContext sheetContext) => UseSmileIDSampleTextMetrics(
      child: Semantics(
        identifier: testId,
        container: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _GrabHandle(),
            Flexible(
              child: SingleChildScrollView(
                // Scrolls rather than clips, so enlarged type cannot push a CTA out of reach.
                padding: EdgeInsets.only(
                  left: _sheetMargin,
                  right: _sheetMargin,
                  bottom:
                      SmileDimens.spacingLg + _navigationBarInset(sheetContext),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (title != null) ...<Widget>[
                      Text(
                        title,
                        style: UseSmileIDSampleType.textStyleHeadingSection
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textTitle,
                            ),
                      ),
                      const SizedBox(height: SmileDimens.spacingSm),
                    ],
                    builder(sheetContext),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The full-height sheet: a back header instead of a handle, for the long pickers.
Future<T?> showUseSmileIDSampleFullHeightSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  String? testId,
}) {
  final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: colors.surface,
    barrierColor: colors.overlayScrim,
    shape: RoundedRectangleBorder(borderRadius: UseSmileIDSampleShapes.sheet),
    constraints: const BoxConstraints.expand(),
    builder: (BuildContext sheetContext) => UseSmileIDSampleTextMetrics(
      child: Semantics(
        identifier: testId,
        container: true,
        child: Column(
          children: <Widget>[
            UseSmileIDSampleSheetHeader(
              title: title,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: _sheetMargin,
                  right: _sheetMargin,
                  bottom: _navigationBarInset(sheetContext),
                ),
                child: builder(sheetContext),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A sheet header is its own pattern: wider margins, and the title left of the control.
class UseSmileIDSampleSheetHeader extends StatelessWidget {
  /// Takes the close action rather than popping itself, so the owner decides what dismiss means.
  const UseSmileIDSampleSheetHeader({
    required this.title,
    required this.onClose,
    super.key,
  });

  /// The sheet's title.
  final String title;

  /// What the back control does.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: _sheetMargin,
      vertical: SmileDimens.spacingXs,
    ),
    child: Row(
      children: <Widget>[
        UseSmileIDSampleTopAppBarButton(
          semanticLabel: 'Close $title',
          onTap: onClose,
          emphasis: UseSmileIDSampleTopAppBarEmphasis.filled,
          glyph: UseSmileIDSampleGlyphs.arrowBack,
        ),
        const SizedBox(width: _sheetHeaderGap),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UseSmileIDSampleType.textStyleTitle.copyWith(
              color: UseSmileIDSampleTheme.colorsOf(context).textTitle,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The 44x5 pill the design puts on partial sheets.
class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SmileDimens.spacingSm),
    child: Container(
      width: SmileDimens.sizeControlMd,
      height: SmileDimens.space4,
      decoration: BoxDecoration(
        color: UseSmileIDSampleTheme.colorsOf(context).border,
        borderRadius: UseSmileIDSampleShapes.chip,
      ),
    ),
  );
}

/// `useSafeArea` leaves the bottom inset to the content.
double _navigationBarInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

/// The design's sheet margins, wider than spacing.md.
const double _sheetMargin = 20;

/// The gap between the header's control and its title.
const double _sheetHeaderGap = 10;
