import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_shell_extension.dart';

import 'support/use_smileid_sample_test_session.dart';

class _Offering extends UseSmileIDSampleShellExtension {
  _Offering(this.session);

  final UseSmileIDSampleTokenSession session;

  @override
  UseSmileIDSampleTokenSession? launchSession() => session;
}

class _Silent extends UseSmileIDSampleShellExtension {}

void main() {
  final List<UseSmileIDSampleTokenSession> linked =
      <UseSmileIDSampleTokenSession>[];
  Future<void> link(UseSmileIDSampleTokenSession session) async =>
      linked.add(session);

  setUp(linked.clear);

  test('links the session the extension offers at launch', () async {
    final UseSmileIDSampleTokenSession session = useSmileIDSampleTestSession();
    await useSmileIDSampleLinkLaunchSession(_Offering(session), link);
    expect(linked, <UseSmileIDSampleTokenSession>[session]);
  });

  test('links nothing without an extension or when it offers none', () async {
    await useSmileIDSampleLinkLaunchSession(null, link);
    await useSmileIDSampleLinkLaunchSession(_Silent(), link);
    expect(linked, isEmpty);
  });
}
