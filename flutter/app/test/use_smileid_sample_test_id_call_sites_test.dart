import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every id `sample_ui` declares is actually rendered by something.
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
