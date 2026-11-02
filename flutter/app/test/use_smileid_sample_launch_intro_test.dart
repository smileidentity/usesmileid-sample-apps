import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_launch.dart';

/// When a launch plays the intro: only from the icon, with animations on.
void main() {
  bool plays(String route, {bool animationsDisabled = false}) =>
      useSmileIDSamplePlaysLaunchIntro(
        UseSmileIDSampleLaunch(route),
        animationsDisabled: animationsDisabled,
      );

  test('a launch from the icon plays it', () {
    expect(plays('/'), isTrue);
  });

  test('a link lands on its destination without it', () {
    expect(plays('usesmileid-sample-flutter://settings'), isFalse);
  });

  test('a launch argument, which rides a link, skips it', () {
    expect(plays('usesmileid-sample-flutter://run?probes=true'), isFalse);
  });

  test('animations turned off in the system skip it', () {
    expect(plays('/', animationsDisabled: true), isFalse);
  });
}
