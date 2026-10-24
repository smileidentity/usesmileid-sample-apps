import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
import 'use_smileid_sample_glyphs.dart';
import 'use_smileid_sample_top_app_bar.dart';

/// A partial sheet's content on the sheet's surface; njia's sheet step draws the window, scrim and dismissal.
class UseSmileIDSamplePartialSheetBody extends StatelessWidget {
  /// [child] under the grab handle and the optional [title].
  const UseSmileIDSamplePartialSheetBody({
    required this.child,
    this.title,
    this.testId,
    super.key,
  });

  /// The sheet's content.
  final Widget child;

  /// The heading over the content, if any.
  final String? title;

  /// The sheet's test id.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // A Material, not a bare colour: njia's sheet route has none, and text and ink need one above them.
    return Material(
      color: colors.surface,
      child: UseSmileIDSampleTextMetrics(
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
                        SmileDimens.spacingLg + _navigationBarInset(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (title != null) ...<Widget>[
                        Text(
                          title!,
                          style: UseSmileIDSampleType.textStyleHeadingSection
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.textTitle,
                              ),
                        ),
                        const SizedBox(height: SmileDimens.spacingSm),
                      ],
                      child,
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
}

/// A full-height sheet's content on the sheet's surface; njia's sheet step draws the window, scrim and dismissal.
class UseSmileIDSampleFullHeightSheetBody extends StatelessWidget {
  /// [child] under a header titled [title] whose back control calls [onClose].
  const UseSmileIDSampleFullHeightSheetBody({
    required this.title,
    required this.onClose,
    required this.child,
    this.testId,
    super.key,
  });

  /// The sheet's title.
  final String title;

  /// What the header's back control does.
  final VoidCallback onClose;

  /// The sheet's content.
  final Widget child;

  /// The sheet's test id.
  final String? testId;

  @override
  Widget build(BuildContext context) => Material(
    color: UseSmileIDSampleTheme.colorsOf(context).surface,
    child: UseSmileIDSampleTextMetrics(
      child: Semantics(
        identifier: testId,
        container: true,
        child: Column(
          children: <Widget>[
            UseSmileIDSampleSheetHeader(title: title, onClose: onClose),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: _sheetMargin,
                  right: _sheetMargin,
                  bottom: _navigationBarInset(context),
                ),
                child: child,
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
          semanticLabel: context.strings.commonCloseNamed(title: title),
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

/// njia's sheet meets the bottom edge, so its content clears the navigation bar itself.
double _navigationBarInset(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom;

/// The design's sheet margins, wider than spacing.md.
const double _sheetMargin = 20;

/// The gap between the header's control and its title.
const double _sheetHeaderGap = 10;
