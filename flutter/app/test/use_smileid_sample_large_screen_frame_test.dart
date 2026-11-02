import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('a phone fills its window', (WidgetTester tester) async {
    final Size window = Size(frame.width, frame.height);

    expect(await drawn(tester, window), Offset.zero & window);
  });
}
