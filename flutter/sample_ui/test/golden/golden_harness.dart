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

/// What a whole screen is hosted at.
const double goldenScreenHeight = 1750;

/// The largest accessibility text scale the no-clipping predicate means.
const double maxTextScale = 2;

/// The key the capture is taken from, so the shot is the component and its padding, not the window.
const Key goldenRoot = Key('golden_root');

/// The text faces plus the emoji face: what every baseline needs.
Future<void> loadSampleFonts() async {
  await loadSampleTextFonts();
  await _loadEmoji();
}

/// The measured faces alone, for a test that reads text metrics and captures nothing.
Future<void> loadSampleTextFonts() async {
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
}

/// Required, not skipped: a baseline drawing tofu instead of emoji is how a picker ships with no flags.
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

  /// Drives the widget into a state only interaction reaches, before each scheme is captured.
  Future<void> Function(WidgetTester tester)? afterPump,
}) async {
  // A disabled shadow records as a SOLID block; restored inline, as the framework checks flags before tear-down.
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
    if (afterPump != null) {
      await afterPump(tester);
      await tester.pump();
    }
    await expectLater(
      find.byKey(goldenRoot),
      matchesGoldenFile('../goldens/${name}_$suffix.png'),
    );
  }
  debugDisableShadows = true;
}

/// One break the text never offered: the word it landed inside, and how that word read across the two lines.
typedef UseSmileIDSampleTextBreak = ({String word, String detail});

/// What the pass found, returned rather than asserted so the rule itself can be tested.
typedef UseSmileIDSampleTextScaleFindings = ({
  List<String> truncated,
  List<UseSmileIDSampleTextBreak> split,
});

/// Pumps the widget at [textScale] and fails on truncated text or a mid-word break.
Future<void> assertSurvivesMaxTextScale(
  WidgetTester tester,
  Widget widget, {
  double textScale = maxTextScale,
  double hostHeight = goldenHostHeight,
  bool ownsScrolling = false,

  /// Words whose breaking is a RECORDED open design question, not a defect this port may fix.
  Set<String> knownOpenWords = const <String>{},

  /// Text whose ellipsis is a RECORDED open question; kept apart so neither half mutes the other.
  Set<String> knownEllipsised = const <String>{},
}) async {
  final UseSmileIDSampleTextScaleFindings findings = await textScaleFindings(
    tester,
    widget,
    textScale: textScale,
    hostHeight: hostHeight,
    ownsScrolling: ownsScrolling,
  );
  // The broken word alone: a paragraph match mutes every other break in any string holding it.
  final List<String> split = findings.split
      .where(
        (UseSmileIDSampleTextBreak it) => !knownOpenWords.any(it.word.contains),
      )
      .map((UseSmileIDSampleTextBreak it) => it.detail)
      .toList();
  final List<String> truncated = findings.truncated
      .where((String it) => !knownEllipsised.any(it.contains))
      .toList();
  expect(
    truncated,
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
    // Scrollable, so exceeding one viewport is not itself a failure.
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
  final List<UseSmileIDSampleTextBreak> split = <UseSmileIDSampleTextBreak>[];
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

  return (truncated: truncated, split: split);
}

/// Every break the text did not offer, a single word included: a column too narrow for its word is the finding.
List<UseSmileIDSampleTextBreak> _midWordBreaks(
  TextPainter painter,
  String text,
) {
  final List<ui.LineMetrics> lines = painter.computeLineMetrics();
  final List<UseSmileIDSampleTextBreak> breaks = <UseSmileIDSampleTextBreak>[];
  for (int line = 0; line < lines.length - 1; line++) {
    final TextPosition position = painter.getPositionForOffset(
      Offset(lines[line].width, lines[line].baseline),
    );
    final TextRange range = painter.getLineBoundary(position);
    final int end = range.end;
    if (end <= 0 || end >= text.length || _breaksCleanly(text, end)) {
      continue;
    }
    breaks.add((
      word: _wordAround(text, end),
      detail: '${text.substring(range.start, end)} | ${text.substring(end)}',
    ));
  }
  return breaks;
}

/// The whitespace-delimited word [index] falls inside, which is what a caller records rather than the line.
String _wordAround(String text, int index) {
  int start = index;
  while (start > 0 && !_isSpace(text[start - 1])) {
    start--;
  }
  int end = index;
  while (end < text.length && !_isSpace(text[end])) {
    end++;
  }
  return text.substring(start, end);
}

/// Whether a break at [index] is one the text itself offered, which is what UAX#14 decides.
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
