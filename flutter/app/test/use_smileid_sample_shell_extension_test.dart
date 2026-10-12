import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_shell_extension.dart';

void main() {
  test('a registry build has no extension', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(useSmileIDSampleShellExtensionProvider), isNull);
  });
}
