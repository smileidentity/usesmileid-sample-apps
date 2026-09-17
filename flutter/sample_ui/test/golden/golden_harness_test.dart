import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// The text-scale rule's own behaviour, pinned because it has been narrowed three times.
///
/// Each narrowing was principled and each could have made it toothless, so both directions are
/// asserted: what it must still catch, and what it must stop reporting.
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
    // "head-turns" wrapping after its hyphen is what a hyphen is for.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('head-turns'),
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

  testWidgets('accepts one unbreakable token, whatever its hyphens', (
    WidgetTester tester,
  ) async {
    // One token in a column too narrow for it has nowhere else to go.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('score-4goals'),
    );
    expect(found.split, isEmpty);
  });

  testWidgets('accepts a token too wide for the whole column', (
    WidgetTester tester,
  ) async {
    // A hex job id has to break somewhere: none of its hyphens offers a break, and no column can
    // take it whole, so breaking it is unavoidable rather than a defect.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('7d2f01aa-4c1e-4b0a-9f2c-1e7b9a3d8c55'),
    );
    expect(found.split, isEmpty);
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

  testWidgets('accepts a single-line field that ellipsises by declaration', (
    WidgetTester tester,
  ) async {
    // A single-line field cannot wrap, so whether its placeholder fits at 2x is a copy question.
    final UseSmileIDSampleTextScaleFindings found = await textScaleFindings(
      tester,
      narrow('Or enter token manually', width: 80, maxLines: 1),
    );
    expect(found.truncated, isEmpty);
  });
}
