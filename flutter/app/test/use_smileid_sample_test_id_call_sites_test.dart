import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every id `sample_ui` declares is actually rendered by something.
///
/// The spec test checks the other direction — that a declared id exists in `spec/`. Both can pass
/// while an id is declared, specified, and attached to no widget, which is how the scenario
/// drawer's row shipped unaddressable: a flow keying off `spec/test-ids.json` would have found
/// nothing there, and no picture could have shown it.
///
/// It lives in the app rather than in `sample_ui` because the sheet ids are supplied by whichever
/// host PRESENTS the sheet, so only a host sees both halves.
void main() {
  test('every declared id is referenced by a screen, component or host', () {
    final File declarations = File(
      '../sample_ui/lib/src/use_smileid_sample_test_ids.dart',
    );
    final Iterable<String> names =
        RegExp(r'static (?:const String|String) (\w+)')
            .allMatches(declarations.readAsStringSync())
            .map((RegExpMatch it) => it.group(1)!);
    expect(names, isNotEmpty, reason: 'the declarations could not be read');

    final String callers =
        <Directory>[Directory('lib'), Directory('../sample_ui/lib')]
            .expand((Directory it) => it.listSync(recursive: true))
            .whereType<File>()
            .where(
              (File it) =>
                  it.path.endsWith('.dart') &&
                  !it.path.endsWith('use_smileid_sample_test_ids.dart'),
            )
            .map((File it) => it.readAsStringSync())
            .join('\n');

    expect(
      names.where(
        (String name) =>
            name != 'all' && !callers.contains('UseSmileIDSampleTestIds.$name'),
      ),
      isEmpty,
      reason: 'declared, specified, and attached to nothing',
    );
  });
}
