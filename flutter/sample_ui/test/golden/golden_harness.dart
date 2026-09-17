import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The width every one of the four platforms renders at, so a crop lands on the same content.
const double goldenWidth = 393;

/// Pinned at 1, which is what a widget baseline rasters at: the capture is one image pixel per
/// logical unit, so a Flutter baseline is 393 wide where Android's is 786 and iOS's 1179.
const double goldenPixelRatio = 1;

/// Tall enough that no capture is clipped by the window, which the boundary crops away anyway.
const double goldenHostHeight = 1400;

/// The largest accessibility text scale the no-clipping predicate means.
const double maxTextScale = 2;

/// The key the capture is taken from, so the shot is the component and its padding, not the window.
const Key goldenRoot = Key('golden_root');

/// Loads the bundled faces, which the test harness otherwise replaces with a blank placeholder.
///
/// Material Icons goes with them: without it the search field's glyph records as an empty box, and
/// a baseline that cannot draw a mark is not coverage of it.
Future<void> loadSampleFonts() async {
  final FontLoader faces = FontLoader(useSmileIDSampleFontFamily);
  for (final String face in <String>['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    final File file = File('assets/fonts/DMSans-$face.ttf');
    faces.addFont(file.readAsBytes().then<ByteData>(ByteData.sublistView));
  }
  await faces.load();

  final FontLoader icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

/// Records one baseline per scheme; `flutter test --update-goldens` writes them.
Future<void> goldens(
  WidgetTester tester,
  String name,
  Widget Function() build, {
  double textScale = 1,
}) async {
  for (final (String suffix, ThemeData theme, UseSmileIDSampleColors colors)
      in <(String, ThemeData, UseSmileIDSampleColors)>[
        ('light', UseSmileIDSampleTheme.light(), UseSmileIDSampleColorSchemes.light),
        ('dark', UseSmileIDSampleTheme.dark(), UseSmileIDSampleColorSchemes.dark),
      ]) {
    await _host(tester, theme, colors, textScale, build());
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('../goldens/${name}_$suffix.png'),
    );
  }
}

/// Pumps the widget at [textScale] and fails on truncated text or a mid-word break.
///
/// Flutter throws on a layout overflow by itself, so this adds the two it does not see: text
/// ellipsised inside its own box, and a line broken between two non-space characters.
Future<void> assertSurvivesMaxTextScale(
  WidgetTester tester,
  Widget widget, {
  double textScale = maxTextScale,
}) async {
  await _host(
    tester,
    UseSmileIDSampleTheme.light(),
    UseSmileIDSampleColorSchemes.light,
    textScale,
    widget,
  );

  final List<RenderParagraph> paragraphs = <RenderParagraph>[];
  void collect(RenderObject node) {
    if (node is RenderParagraph) {
      paragraphs.add(node);
    }
    node.visitChildren(collect);
  }

  collect(tester.renderObject(find.byKey(goldenRoot)));
  expect(paragraphs, isNotEmpty, reason: 'collected no text to check at ${textScale}x');

  final List<String> truncated = <String>[];
  final List<String> split = <String>[];
  for (final RenderParagraph paragraph in paragraphs) {
    final String text = paragraph.text.toPlainText();
    final TextPainter painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textAlign: paragraph.textAlign,
      maxLines: paragraph.maxLines,
      textScaler: paragraph.textScaler,
      ellipsis: paragraph.overflow == TextOverflow.ellipsis ? '…' : null,
    )..layout(maxWidth: paragraph.size.width);
    if (painter.didExceedMaxLines) {
      truncated.add(text);
    }
    split.addAll(_midWordBreaks(painter, text));
    painter.dispose();
  }

  expect(truncated, isEmpty, reason: 'text clipped or ellipsised at ${textScale}x text scale');
  expect(split, isEmpty, reason: 'a word broke across lines at ${textScale}x text scale');
}

/// Each break that landed between two non-space characters, reported as the two halves it made.
List<String> _midWordBreaks(TextPainter painter, String text) {
  final List<ui.LineMetrics> lines = painter.computeLineMetrics();
  final List<String> breaks = <String>[];
  for (int line = 0; line < lines.length - 1; line++) {
    final TextPosition position = painter.getPositionForOffset(
      Offset(lines[line].width, lines[line].baseline),
    );
    final TextRange range = painter.getLineBoundary(position);
    final int end = range.end;
    if (end > 0 &&
        end < text.length &&
        !_isWhitespace(text[end - 1]) &&
        !_isWhitespace(text[end])) {
      breaks.add('${text.substring(range.start, end)} | ${text.substring(end)}');
    }
  }
  return breaks;
}

bool _isWhitespace(String character) => character.trim().isEmpty;

Future<void> _host(
  WidgetTester tester,
  ThemeData theme,
  UseSmileIDSampleColors colors,
  double textScale,
  Widget child,
) async {
  tester.view
    ..devicePixelRatio = goldenPixelRatio
    ..physicalSize = const Size(
      goldenWidth * goldenPixelRatio,
      goldenHostHeight * goldenPixelRatio,
    );
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      // Copied onto the view's own data, not replaced: a bare MediaQueryData reports density 1 and
      // a zero-sized window, which silently rasters every baseline at the wrong scale.
      data: MediaQueryData.fromView(
        tester.view,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        // Keyed per scheme so the second capture builds a fresh tree. MaterialApp animates a theme
        // change, so without this the dark baseline records the light scheme mid-transition.
        key: ValueKey<Brightness>(theme.brightness),
        theme: theme,
        debugShowCheckedModeBanner: false,
        home: Align(
          alignment: Alignment.topLeft,
          // The boundary is what crops the capture to the component and its padding; without one
          // the shot is the whole window, with bare host either side of a 393-wide column.
          child: RepaintBoundary(
            key: goldenRoot,
            child: Container(
              width: goldenWidth,
              color: colors.background,
              padding: const EdgeInsets.all(SmileDimens.spacingMd),
              // Every real screen sits on a Scaffold, and a text field asserts on the ancestor it
              // provides; transparency supplies it without painting over the page colour.
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  // Not pumpAndSettle: the button's loading indicator animates indefinitely, so settling never
  // returns. One extra frame is all static content needs, and no baseline captures the indicator.
  await tester.pump();
}
