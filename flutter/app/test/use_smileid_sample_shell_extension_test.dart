import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_shell_extension.dart';

void main() {
  test('a registry build has no extension', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(useSmileIDSampleShellExtensionProvider), isNull);
  });

  test("the extension's leading rows come before its others", () {
    const Widget leading = Text('leading');
    const Widget others = Text('others');

    expect(
      useSmileIDSampleDebugRows(_Rows(leading: leading, others: others)),
      <Widget>[leading, others],
    );
  });

  test('a build without an extension has no debug rows', () {
    expect(useSmileIDSampleDebugRows(null), isEmpty);
  });
}

/// An extension with one leading row and one other.
class _Rows extends UseSmileIDSampleShellExtension {
  _Rows({required this.leading, required this.others});

  final Widget leading;
  final Widget others;

  @override
  List<Widget> leadingDebugRows() => <Widget>[leading];

  @override
  List<Widget> debugRows() => <Widget>[others];
}
