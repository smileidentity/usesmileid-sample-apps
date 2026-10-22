import 'package:flutter/foundation.dart';
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

class _Failing extends UseSmileIDSampleShellExtension {
  @override
  UseSmileIDSampleTokenSession? launchSession() =>
      throw StateError('no session to offer');
}

class _Recording extends UseSmileIDSampleShellExtension {
  final List<String> calls = <String>[];

  @override
  Future<void> onLaunch(String defaultRouteName) async {
    await Future<void>.delayed(Duration.zero);
    calls.add('onLaunch $defaultRouteName');
  }

  @override
  UseSmileIDSampleTokenSession? launchSession() {
    calls.add('launchSession');
    return null;
  }
}

class _Throwing extends UseSmileIDSampleShellExtension {
  bool asked = false;

  @override
  Future<void> onLaunch(String defaultRouteName) async =>
      throw ArgumentError.value(defaultRouteName, 'e2eScenario');

  @override
  UseSmileIDSampleTokenSession? launchSession() {
    asked = true;
    return null;
  }
}

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

  test('a failed link only skips the launch session', () async {
    await useSmileIDSampleLinkLaunchSession(
      _Offering(useSmileIDSampleTestSession()),
      (UseSmileIDSampleTokenSession session) async =>
          throw StateError('secure storage refused the write'),
    );
  });

  test('an extension that fails to offer a session only skips it', () async {
    await useSmileIDSampleLinkLaunchSession(_Failing(), link);
    expect(linked, isEmpty);
  });

  test(
    'runs onLaunch to completion before it asks for the launch session',
    () async {
      final _Recording extension = _Recording();
      expect(
        await useSmileIDSampleLaunchExtension(
          extension,
          '/?e2eScenario=x',
          link,
        ),
        isNull,
      );
      expect(extension.calls, <String>[
        'onLaunch /?e2eScenario=x',
        'launchSession',
      ]);
    },
  );

  test('launches nothing without an extension', () async {
    await useSmileIDSampleLaunchExtension(null, '/', link);
    expect(linked, isEmpty);
  });

  test(
    'reports and returns a throw from onLaunch, before the session is asked for',
    () async {
      final List<FlutterErrorDetails> reported = <FlutterErrorDetails>[];
      final FlutterExceptionHandler? onError = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = onError);
      final _Throwing extension = _Throwing();
      expect(
        await useSmileIDSampleLaunchExtension(
          extension,
          '/?e2eScenario=x',
          link,
        ),
        isArgumentError,
      );
      expect(extension.asked, isFalse);
      expect(reported.single.exception, isArgumentError);
      expect(reported.single.stack, isNotNull);
    },
  );
}
