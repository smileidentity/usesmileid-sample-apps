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

/// What a whole screen is hosted at. A screen owns a scroll view, which fills its constraints, so
/// the host is the only thing that decides how much of it lays out — and a one-viewport host is the
/// blind spot `port-patterns.md` §6 records, where the settings footer appeared in no baseline.
const double goldenScreenHeight = 1750;

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
  for (final String face in <String>[
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
  ]) {
    final File file = File('assets/fonts/DMSans-$face.ttf');
    faces.addFont(file.readAsBytes().then<ByteData>(ByteData.sublistView));
  }
  await faces.load();

  final FontLoader icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();

  await _loadEmoji();
}

/// The country flags and the picker leads are emoji, and a baseline that draws tofu instead is not
/// coverage of them. Required rather than skipped: the lane is pinned to macOS precisely so a
/// baseline means one thing, and a silent tofu is how a picker ships with no flags.
Future<void> _loadEmoji() async {
  final File file = File(_appleColorEmoji);
  if (!file.existsSync()) {
    throw StateError(
      'no emoji font at $_appleColorEmoji; goldens record flags and picker leads as tofu without '
      'it, so record them on macOS as .github/workflows/flutter.yml pins',
    );
  }
  final FontLoader emoji = FontLoader('Apple Color Emoji')
    ..addFont(file.readAsBytes().then<ByteData>(ByteData.sublistView));
  await emoji.load();
}

/// The system face, which is where every Apple platform's emoji come from.
const String _appleColorEmoji = '/System/Library/Fonts/Apple Color Emoji.ttc';

/// Records one baseline per scheme; `flutter test --update-goldens` writes them.
Future<void> goldens(
  WidgetTester tester,
  String name,
  Widget Function() build, {
  double textScale = 1,
  double hostHeight = goldenHostHeight,

  /// True for a whole screen, which owns a scroll view and so needs a bounded height to lay out.
  bool fillsHost = false,
}) async {
  // A disabled shadow records as a SOLID block, which drew the nav bar's elevation as a hard ring
  // and hid the token ring behind it. Restored inline, because the framework asserts every
  // painting flag is back before a test's tear-downs run.
  debugDisableShadows = false;
  for (final (String suffix, ThemeData theme, UseSmileIDSampleColors colors)
      in <(String, ThemeData, UseSmileIDSampleColors)>[
        (
          'light',
          UseSmileIDSampleTheme.light(),
          UseSmileIDSampleColorSchemes.light,
        ),
        (
          'dark',
          UseSmileIDSampleTheme.dark(),
          UseSmileIDSampleColorSchemes.dark,
        ),
      ]) {
    await _host(
      tester,
      theme,
      colors,
      textScale,
      build(),
      hostHeight: hostHeight,
      fillsHost: fillsHost,
    );
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('../goldens/${name}_$suffix.png'),
    );
  }
  debugDisableShadows = true;
}

/// What the text-scale pass found: text ellipsised where it could have wrapped, and words broken
/// where the text offered no break.
///
/// Returned rather than asserted so the rule itself is testable — `flutter_test` marks a test
/// failed by a nested `expect` even when the caller catches it.
typedef UseSmileIDSampleTextScaleFindings = ({
  List<String> truncated,
  List<String> split,
});

/// Pumps the widget at [textScale] and fails on truncated text or a mid-word break.
///
/// Flutter throws on a layout overflow by itself, so this adds the two it does not see: text
/// ellipsised inside its own box, and a word broken where nothing offered a break.
Future<void> assertSurvivesMaxTextScale(
  WidgetTester tester,
  Widget widget, {
  double textScale = maxTextScale,
  double hostHeight = goldenHostHeight,
  bool ownsScrolling = false,

  /// Words whose breaking is a RECORDED open design question rather than a defect this port may
  /// fix — `ui-work-plan.md` §5 item 3a. Naming them keeps the rule strict everywhere else and
  /// makes a green run say "the known open item", not "nothing to see".
  Set<String> knownOpenWords = const <String>{},
}) async {
  final UseSmileIDSampleTextScaleFindings findings = await textScaleFindings(
    tester,
    widget,
    textScale: textScale,
    hostHeight: hostHeight,
    ownsScrolling: ownsScrolling,
  );
  final List<String> split = findings.split
      .where(
        (String it) => !knownOpenWords.any(it.replaceAll(' | ', '').contains),
      )
      .toList();
  expect(
    findings.truncated,
    isEmpty,
    reason: 'text clipped or ellipsised at ${textScale}x text scale',
  );
  expect(
    split,
    isEmpty,
    reason: 'a word broke across lines at ${textScale}x text scale',
  );
}

/// The same pass, reporting instead of asserting.
Future<UseSmileIDSampleTextScaleFindings> textScaleFindings(
  WidgetTester tester,
  Widget widget, {
  double textScale = maxTextScale,
  double hostHeight = goldenHostHeight,
  bool ownsScrolling = false,
}) async {
  await _host(
    tester,
    UseSmileIDSampleTheme.light(),
    UseSmileIDSampleColorSchemes.light,
    textScale,
    widget,
    // Scrollable, so exceeding one viewport is not itself a failure: at 2x a list legitimately
    // runs past the screen, and this predicate is about truncation and word breaks. Horizontal
    // overflow still throws on its own, which is the direction that means clipping. A screen owns
    // its own scroll view, and nesting two gives the inner one unbounded height.
    scrollable: !ownsScrolling,
    hostHeight: hostHeight,
    fillsHost: ownsScrolling,
  );

  final List<RenderParagraph> paragraphs = <RenderParagraph>[];
  void collect(RenderObject node) {
    if (node is RenderParagraph) {
      paragraphs.add(node);
    }
    node.visitChildren(collect);
  }

  collect(tester.renderObject(find.byKey(goldenRoot)));
  expect(
    paragraphs,
    isNotEmpty,
    reason: 'collected no text to check at ${textScale}x',
  );

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
    // Only where the paragraph is allowed to wrap. A single-line paragraph has declared that it
    // ellipsises instead, which a text field cannot avoid — whether the chosen copy fits at 2x is
    // a question for the baseline and the device pass, not a layout defect.
    if (painter.didExceedMaxLines && paragraph.maxLines != 1) {
      truncated.add(text);
    }
    split.addAll(_midWordBreaks(painter, text));
    painter.dispose();
  }

  return (truncated: truncated, split: split);
}

/// Each break that split a word in text that had somewhere else to put it.
///
/// A paragraph of ONE token has nowhere else to go — a hex job id is the case that proves it, since
/// UAX#14 refuses a break before a digit and so no hyphen in a UUID offers one — so breaking it is
/// unavoidable rather than a defect. In text of two or more words, a break inside a word says the
/// column is too narrow for the text at this scale, which is the finding: it is how an app bar
/// shipped "Sca / n / tok / en" through a green lane.
///
/// Measuring the token instead, and exempting one too wide for the column, makes this unreachable:
/// a line breaker only splits a word that cannot fit, so every case would be exempt.
List<String> _midWordBreaks(TextPainter painter, String text) {
  if (!text.trim().contains(RegExp(r'\s'))) {
    return const <String>[];
  }
  final List<ui.LineMetrics> lines = painter.computeLineMetrics();
  final List<String> breaks = <String>[];
  for (int line = 0; line < lines.length - 1; line++) {
    final TextPosition position = painter.getPositionForOffset(
      Offset(lines[line].width, lines[line].baseline),
    );
    final TextRange range = painter.getLineBoundary(position);
    final int end = range.end;
    if (end <= 0 || end >= text.length || _breaksCleanly(text, end)) {
      continue;
    }
    breaks.add('${text.substring(range.start, end)} | ${text.substring(end)}');
  }
  return breaks;
}

/// Whether a break at [index] is one the text itself offered, which is what UAX#14 decides.
///
/// Whitespace always offers one. A hyphen offers one too — that is what a hyphen is for, so
/// "head-turns" wrapping after the hyphen is correct — EXCEPT before a digit, which is the rule
/// that stops "3-4" splitting and is also why no hyphen in a hex job id offers anything. Getting
/// this wrong in either direction costs a real finding: too strict and every hyphenated label is
/// reported, too loose and a hex id looks like four short tokens that each fit.
bool _breaksCleanly(String text, int index) {
  if (_isSpace(text[index - 1]) || _isSpace(text[index])) {
    return true;
  }
  return _isHyphen(text[index - 1]) && !_isDigit(text[index]);
}

bool _isSpace(String character) => character.trim().isEmpty;

bool _isHyphen(String character) =>
    character == '-' || character == '\u2013' || character == '\u2014';

bool _isDigit(String character) => character.codeUnitAt(0) ^ 0x30 <= 9;

Future<void> _host(
  WidgetTester tester,
  ThemeData theme,
  UseSmileIDSampleColors colors,
  double textScale,
  Widget child, {
  bool scrollable = false,
  double hostHeight = goldenHostHeight,
  bool fillsHost = false,
}) async {
  tester.view
    ..devicePixelRatio = goldenPixelRatio
    ..physicalSize = Size(
      goldenWidth * goldenPixelRatio,
      hostHeight * goldenPixelRatio,
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
              height: fillsHost ? hostHeight : null,
              color: colors.background,
              padding: const EdgeInsets.all(SmileDimens.spacingMd),
              // Every real screen sits on a Scaffold, and a text field asserts on the ancestor it
              // provides; transparency supplies it without painting over the page colour.
              child: Material(
                type: MaterialType.transparency,
                child: scrollable ? SingleChildScrollView(child: child) : child,
              ),
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
