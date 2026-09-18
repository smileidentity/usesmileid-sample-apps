import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// The text-scale rule's own behaviour, pinned because it has been narrowed three times.
void main() {
  setUpAll(loadSampleFonts);

  Widget narrow(String text, {double width = 44, int? maxLines}) => Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      ),
    ),
  );

  testWidgets('catches a word broken where the text offered no break', (
    WidgetTester tester,
  ) async {
    // The defect the rule exists for: an app bar shipped "Sca / n / tok / en" through a green lane,
    // because wrapped text never truncates and nothing else sees it.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('Scan token'),
    );
    expect(found.split, isNotEmpty);
  });

  testWidgets('accepts a break the hyphen itself offered', (
    WidgetTester tester,
  ) async {
    // Wide enough that the hyphen's break is the one taken; at 44 the word breaks everywhere and
    // the case under test never arises.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('head-turns', width: 110),
    );
    expect(found.split, isEmpty);
  });

  testWidgets('catches a break before a digit in text with room elsewhere', (
    WidgetTester tester,
  ) async {
    // No hyphen offers a break before a digit — UAX#14's rule that keeps "3-4" whole — so this
    // splits inside a word, and with a second word present the text had somewhere else to go.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('score-4goals here', width: 120),
    );
    expect(found.split, isNotEmpty);
  });

  testWidgets('catches a lone word broken by a column too narrow for it', (
    WidgetTester tester,
  ) async {
    // The nav bar shipped "Verifi / cations" through a green lane: a rule that skipped any text
    // without a space could not see a label that is one word.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('Verifications'),
    );
    expect(found.split, isNotEmpty);
  });

  testWidgets('records a token no column can take, rather than exempting it', (
    WidgetTester tester,
  ) async {
    // A hex job id has to break somewhere, which is a caller's judgement about its column and not
    // something the rule can decide for every string in the app.
    await assertSurvivesMaxTextScale(
      tester,
      narrow('7d2f01aa-4c1e-4b0a-9f2c-1e7b9a3d8c55'),
      knownOpenWords: const <String>{'7d2f01aa-4c1e'},
    );
  });

  testWidgets('accepts text that wraps between words', (
    WidgetTester tester,
  ) async {
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('one two', width: 120),
    );
    expect(found.split, isEmpty);
  });

  testWidgets('catches text ellipsised where it was allowed to wrap', (
    WidgetTester tester,
  ) async {
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('Enhanced Document Verification', width: 80, maxLines: 2),
    );
    expect(found.truncated, isNotEmpty);
  });

  testWidgets('catches a single-line field ellipsised at scale', (
    WidgetTester tester,
  ) async {
    // `maxLines != 1` excluded every Text in the app, so this half of the rule could not fail.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('Or enter token manually', width: 80, maxLines: 1),
    );
    expect(found.truncated, isNotEmpty);
  });

  testWidgets('records a single-line field whose copy is the open question', (
    WidgetTester tester,
  ) async {
    await assertSurvivesMaxTextScale(
      tester,
      narrow('Or enter token manually', width: 80, maxLines: 1),
      knownEllipsised: const <String>{'Or enter token manually'},
    );
  });

  testWidgets('records one word without muting the rest of its line', (
    WidgetTester tester,
  ) async {
    // A record naming the paragraph rather than the word switched the rule off for every other
    // word in any string that contained it.
    Object? thrown;
    try {
      await assertSurvivesMaxTextScale(
        tester,
        narrow('Settings unbreakablelongword', width: 120),
        knownOpenWords: const <String>{'Settings'},
      );
    } on TestFailure catch (failure) {
      thrown = failure;
    }
    expect(thrown, isA<TestFailure>());
  });

  testWidgets('a recorded break does not also excuse an ellipsis', (
    WidgetTester tester,
  ) async {
    // One set across both halves would have let the nav bar's labels be capped, which is the very
    // thing recording them as breaking says not to do.
    Object? thrown;
    try {
      await assertSurvivesMaxTextScale(
        tester,
        narrow('Verifications', width: 60, maxLines: 1),
        knownOpenWords: const <String>{'Verifications'},
      );
    } on TestFailure catch (failure) {
      thrown = failure;
    }
    expect(thrown, isA<TestFailure>());
  });
}
