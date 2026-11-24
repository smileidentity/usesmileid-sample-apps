import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_top_cutout.dart';

/// A top cutout as the engine reports it, which the host leaves to the native reading.
const DisplayFeature _engineTopCutout = DisplayFeature(
  bounds: Rect.fromLTWH(20, 0, 30, 35),
  type: DisplayFeatureType.cutout,
  state: DisplayFeatureState.unknown,
);

/// A punch-hole phone's status bar.
const double _statusBar = 37;

/// A three-button navigation bar, which the keyboard covers.
const double _navigationBar = 48;

/// The shell reads a top camera cutout natively and hands the shared screens whether they sit under it.
void main() {
  late Object? Function() nativeAnswer;
  late int asked;

  setUp(() {
    nativeAnswer = () => true;
    asked = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(useSmileIDSampleCutoutChannel, (
          MethodCall call,
        ) async {
          asked++;
          return nativeAnswer();
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(useSmileIDSampleCutoutChannel, null);
  });

  void setView(
    WidgetTester tester, {
    double statusBar = 37,
    List<DisplayFeature> features = const <DisplayFeature>[],
  }) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1080, 2400)
      ..viewPadding = FakeViewPadding(top: statusBar, bottom: _navigationBar)
      ..padding = FakeViewPadding(top: statusBar, bottom: _navigationBar)
      ..displayFeatures = features;
    addTearDown(tester.view.reset);
  }

  late bool present;

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      UseSmileIDSampleTopCutoutHost(
        child: Builder(
          builder: (BuildContext context) {
            present = UseSmileIDSampleTopCutout.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'on Android it reports a cutout the native side reads',
    (WidgetTester tester) async {
      setView(tester);
      await pumpHost(tester);

      expect(present, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    "it follows the native reading where the engine's disagrees",
    (WidgetTester tester) async {
      nativeAnswer = () => false;
      setView(tester, features: <DisplayFeature>[_engineTopCutout]);
      await pumpHost(tester);

      expect(present, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'the first frame already carries the reading taken before launch',
    (WidgetTester tester) async {
      setView(tester);
      await tester.pumpWidget(
        UseSmileIDSampleTopCutoutHost(
          initial: true,
          child: Builder(
            builder: (BuildContext context) {
              present = UseSmileIDSampleTopCutout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(present, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a window not ready to answer keeps the reading it had',
    (WidgetTester tester) async {
      nativeAnswer = () => null;
      setView(tester);
      await tester.pumpWidget(
        UseSmileIDSampleTopCutoutHost(
          initial: true,
          child: Builder(
            builder: (BuildContext context) {
              present = UseSmileIDSampleTopCutout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(present, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'without a status bar it reports none',
    (WidgetTester tester) async {
      setView(tester, statusBar: 0);
      await pumpHost(tester);

      expect(present, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a rotation reads it again',
    (WidgetTester tester) async {
      setView(tester);
      await pumpHost(tester);
      expect(present, isTrue);

      nativeAnswer = () => false;
      tester.view.physicalSize = const Size(2400, 1080);
      await tester.pumpAndSettle();

      expect(present, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a keyboard opening does not ask again',
    (WidgetTester tester) async {
      setView(tester);
      await pumpHost(tester);
      final int before = asked;

      tester.view
        ..viewPadding = FakeViewPadding(top: _statusBar, bottom: _navigationBar)
        ..padding = FakeViewPadding(top: _statusBar)
        ..viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(asked, before);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a status bar change with the same inset still reads it again',
    (WidgetTester tester) async {
      setView(tester);
      await pumpHost(tester);
      expect(present, isTrue);

      nativeAnswer = () => false;
      tester.view.padding = const FakeViewPadding(top: 0);
      await tester.pumpAndSettle();

      expect(present, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'on iOS it never asks and reports none',
    (WidgetTester tester) async {
      setView(tester);
      await pumpHost(tester);

      expect(present, isFalse);
      expect(asked, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'with no native side behind it, it reports none',
    (WidgetTester tester) async {
      nativeAnswer = () => throw MissingPluginException();
      setView(tester);
      await pumpHost(tester);

      expect(present, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'a native error leaves it reporting none',
    (WidgetTester tester) async {
      nativeAnswer = () => throw PlatformException(code: 'unavailable');
      setView(tester);
      await pumpHost(tester);

      expect(present, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
