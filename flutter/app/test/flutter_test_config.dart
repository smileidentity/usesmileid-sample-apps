import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs each widget test in a phone's window, the size the journeys are designed at, where Flutter's default 800 × 600 window is a large screen that frames the app; a test that sizes its own window still does.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    // Only a file with widget tests has a binding; starting one here would answer every other file's HTTP with a 400.
    if (BindingBase.debugBindingType() == null) {
      return;
    }
    final TestFlutterView view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.devicePixelRatio = 3;
    view.physicalSize = const Size(390, 844) * 3;
  });
  tearDown(() {
    if (BindingBase.debugBindingType() != null) {
      TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset();
    }
  });
  await testMain();
}
