import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The intro's choreography as a pure function of progress, so its named frames hold still.
void main() {
  UseSmileIDSampleLaunchIntroPose at(double progress) =>
      UseSmileIDSampleLaunchIntroTimeline.pose(progress);

  test('the first frame is an empty screen', () {
    final UseSmileIDSampleLaunchIntroPose pose = at(0);

    expect(pose.markAlpha, 0);
    expect(pose.wordmarkReveal, 0);
  });

  test('the logo starts unlocked, at its own size', () {
    final UseSmileIDSampleLaunchIntroPose pose = at(
      UseSmileIDSampleLaunchIntroTimeline.appeared,
    );

    expect(pose.markAlpha, 1);
    expect(pose.markScale, 1);
    expect(pose.shackleLock, 0);
  });

  test('the lock shuts while the name is still unrolling', () {
    final UseSmileIDSampleLaunchIntroPose pose = at(
      UseSmileIDSampleLaunchIntroTimeline.locked,
    );

    expect(pose.shackleLock, 1);
    expect(pose.shackleLift, 0);
    expect(
      pose.wordmarkReveal > 0 && pose.wordmarkReveal < 1,
      isTrue,
      reason: 'the name is part-way out',
    );
  });

  test('the last frame is the logo at rest, unlocked again', () {
    expect(at(1), UseSmileIDSampleLaunchIntroPose.rest);
  });

  test('the shackle only ever lifts, never sinks into the body', () {
    final Iterable<double> lifts = <int>[
      for (int step = 0; step <= 1000; step++) step,
    ].map((int step) => at(step / 1000).shackleLift);

    expect(lifts.every((double lift) => lift >= 0), isTrue);
  });

  test('progress outside the timeline is clamped', () {
    expect(at(-1), at(0));
    expect(at(2), at(1));
  });
}
