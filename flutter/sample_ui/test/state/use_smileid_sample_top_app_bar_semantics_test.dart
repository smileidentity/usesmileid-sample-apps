import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The app bar's controls have to be reachable one at a time, which a golden cannot show.
///
/// Found when the detail page became the app bar's first caller: with no trailing action the whole
/// row collapsed into one node labelled 'Back\nTitle', flagged as a button. A screen reader
/// announced the title as part of the back control, and neither could be reached alone.
void main() {
  /// Every labelled node in the tree, with the flags that decide how it is announced.
  List<({String label, bool button, bool header})> labelledNodes(
    WidgetTester tester,
  ) {
    final List<({String label, bool button, bool header})> found =
        <({String label, bool button, bool header})>[];
    void walk(SemanticsNode node) {
      if (node.label.isNotEmpty) {
        found.add((
          label: node.label,
          button: node.flagsCollection.isButton,
          header: node.flagsCollection.isHeader,
        ));
      }
      node.visitChildren((SemanticsNode child) {
        walk(child);
        return true;
      });
    }

    // The non-deprecated `rootPipelineOwner` holds no semantics owner in a widget test, so this
    // stays on the deprecated one until a replacement exists that actually works here.
    // ignore: deprecated_member_use
    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    return found;
  }

  Future<List<({String label, bool button, bool header})>> pumpBar(
    WidgetTester tester, {
    Widget? action,
  }) async {
    // Disposed INLINE, not in a tear-down: flutter_test verifies no handle is live before its
    // tear-downs run, so a deferred dispose fails the test it was meant to clean up after. The
    // nodes are plain records by the time this returns, so nothing needs semantics to stay on.
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: UseSmileIDSampleTheme.light(),
        home: UseSmileIDSampleTopAppBar(
          title: 'Verification details',
          onBack: () {},
          action: action,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final List<({String label, bool button, bool header})> nodes =
        labelledNodes(tester);
    semantics.dispose();
    return nodes;
  }

  // The configuration that was broken, and the one most screens use: back and a title, no action.
  testWidgets('with no action the back control and the title stay apart', (
    WidgetTester tester,
  ) async {
    final List<({String label, bool button, bool header})> nodes =
        await pumpBar(tester);

    expect(nodes.map((n) => n.label), <String>['Back', 'Verification details']);
    expect(nodes.first.button, isTrue);
    expect(nodes.last.header, isTrue, reason: 'the header is the title');
    expect(
      nodes.last.button,
      isFalse,
      reason: 'a title announced as a button offers an action it does not have',
    );
  });

  testWidgets('with an action all three are separately reachable', (
    WidgetTester tester,
  ) async {
    final List<({String label, bool button, bool header})> nodes =
        await pumpBar(
          tester,
          action: UseSmileIDSampleTopAppBarButton(
            semanticLabel: 'Hide verification from the app list',
            onTap: () {},
            glyph: UseSmileIDSampleGlyphs.trash,
          ),
        );

    expect(nodes.map((n) => n.label), <String>[
      'Back',
      'Verification details',
      'Hide verification from the app list',
    ]);
  });

  // The symptom the merge produced, asserted directly: no node may carry two controls' words.
  testWidgets('no node carries more than one label', (
    WidgetTester tester,
  ) async {
    for (final List<({String label, bool button, bool header})> nodes
        in <List<({String label, bool button, bool header})>>[
          await pumpBar(tester),
          await pumpBar(
            tester,
            action: UseSmileIDSampleTopAppBarButton(
              semanticLabel: 'Hide',
              onTap: () {},
              glyph: UseSmileIDSampleGlyphs.trash,
            ),
          ),
        ]) {
      for (final ({String label, bool button, bool header}) node in nodes) {
        expect(
          node.label,
          isNot(contains('\n')),
          reason: 'merged: ${node.label.replaceAll('\n', ' + ')}',
        );
      }
    }
  });
}
