import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_large_screen_frame.dart';

/// On a large screen the app draws its own screens in the largest phone's frame, centred; a phone, and the full-screen SDK run, fill the window.
void main() {
  const Key screen = Key('screen');

  test("the frames are the spec's", () {
    final Map<String, dynamic> spec =
        jsonDecode(
              File('../../spec/large-screen-frame.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final Map<String, dynamic> frames = spec['frames'] as Map<String, dynamic>;

    Size frameOf(String platform) {
      final Map<String, dynamic> frame =
          frames[platform] as Map<String, dynamic>;
      return Size(
        (frame['width'] as num).toDouble(),
        (frame['height'] as num).toDouble(),
      );
    }

    expect(UseSmileIDSampleLargeScreen.minSide, spec['largeScreenMinSide']);
    expect(UseSmileIDSampleLargeScreen.iosFrame, frameOf('ios'));
    expect(UseSmileIDSampleLargeScreen.androidFrame, frameOf('android'));
  });

  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    final Size frame = UseSmileIDSampleLargeScreen.frameOn(platform);

    Size? frameIn(double width, double height) {
      final Size window = Size(width, height);
      return UseSmileIDSampleLargeScreen.frameSize(window, window, platform);
    }

    group('on ${platform.name}', () {
      test("a large screen draws the app in the largest phone's frame", () {
        expect(frameIn(800, 1280), frame);
        expect(frameIn(600, 960), frame);
        expect(frameIn(1280, 800), Size(frame.width, 800));
      });

      test('a phone draws the app across its whole window', () {
        expect(frameIn(frame.width, frame.height), isNull);
        expect(frameIn(frame.height, frame.width), isNull);
        expect(frameIn(599, 1280), isNull);
      });

      test("a side shorter than its frame keeps the safe area's length", () {
        expect(
          UseSmileIDSampleLargeScreen.frameSize(
            const Size(1280, 800),
            const Size(1280, 728),
            platform,
          ),
          Size(frame.width, 728),
        );
      });
    });
  }

  Future<Rect> drawn(
    WidgetTester tester,
    Size window, {
    bool framed = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = window;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: window),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: UseSmileIDSampleLargeScreenFrame(
            framed: framed,
            child: const SizedBox.expand(key: screen),
          ),
        ),
      ),
    );
    return tester.getRect(find.byKey(screen));
  }

  Future<bool> framedSeenInside(
    WidgetTester tester,
    Size window, {
    bool framed = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = window;
    addTearDown(tester.view.reset);
    late bool seen;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: window),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: UseSmileIDSampleLargeScreenFrame(
            framed: framed,
            child: Builder(
              builder: (BuildContext context) {
                seen = UseSmileIDSampleLargeScreenFramed.of(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    return seen;
  }

  testWidgets(
    "the screens in a large screen's frame are told the status bar is outside it",
    (WidgetTester tester) async {
      expect(await framedSeenInside(tester, const Size(800, 1280)), isTrue);
    },
  );

  testWidgets("a phone's screens are not framed", (WidgetTester tester) async {
    expect(await framedSeenInside(tester, const Size(384, 832)), isFalse);
  });

  testWidgets('the full-screen SDK run is not framed', (
    WidgetTester tester,
  ) async {
    expect(
      await framedSeenInside(tester, const Size(800, 1280), framed: false),
      isFalse,
    );
  });

  testWidgets(
    'the screens keep their state when the frame steps aside and back',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);
      int mounts = 0;
      Future<void> pump({required bool framed}) => tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1280)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: UseSmileIDSampleLargeScreenFrame(
              framed: framed,
              child: _Probe(onMount: () => mounts++),
            ),
          ),
        ),
      );

      await pump(framed: true);
      await pump(framed: false);
      await pump(framed: true);

      expect(mounts, 1);
    },
  );

  final Size frame = UseSmileIDSampleLargeScreen.frameOn(defaultTargetPlatform);

  testWidgets('a large screen centres the frame', (WidgetTester tester) async {
    const Size window = Size(800, 1280);

    expect(
      await drawn(tester, window),
      Rect.fromLTWH(
        (window.width - frame.width) / 2,
        (window.height - frame.height) / 2,
        frame.width,
        frame.height,
      ),
    );
  });

  testWidgets('the full-screen SDK run fills the window', (
    WidgetTester tester,
  ) async {
    const Size window = Size(800, 1280);

    expect(await drawn(tester, window, framed: false), Offset.zero & window);
  });

  testWidgets('a keyboard over the frame takes only the part it covers', (
    WidgetTester tester,
  ) async {
    const Size window = Size(800, 1280);
    EdgeInsets? keyboard;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = window;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: window,
          viewInsets: EdgeInsets.only(bottom: 500),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: UseSmileIDSampleLargeScreenFrame(
            framed: true,
            child: Builder(
              builder: (BuildContext context) {
                keyboard = MediaQuery.viewInsetsOf(context);
                return const SizedBox.expand(key: screen);
              },
            ),
          ),
        ),
      ),
    );
    final double belowFrame = (window.height - frame.height) / 2;

    expect(keyboard, EdgeInsets.only(bottom: 500 - belowFrame));
    expect(
      tester.getRect(find.byKey(screen)).top,
      (window.height - frame.height) / 2,
    );
  });

  testWidgets('a phone fills its window', (WidgetTester tester) async {
    final Size window = Size(frame.width, frame.height);

    expect(await drawn(tester, window), Offset.zero & window);
  });
}

/// A stateful stand-in for the app, which counts how often its state is created.
class _Probe extends StatefulWidget {
  const _Probe({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
