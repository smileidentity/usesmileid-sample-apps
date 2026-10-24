import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_launch.dart';

/// The cold-start link: the link it opens, and what arguments it carried.
void main() {
  UseSmileIDSampleLaunch at(String route) => UseSmileIDSampleLaunch(route);

  group('the link', () {
    test('is none when the app was opened from the icon', () {
      expect(at('/').link, isNull);
      expect(at('').link, isNull);
    });

    // Measured on a device: a custom-scheme link arrives whole, scheme and host included.
    test(
      'is the whole custom-scheme link, which the shell folds into a graph path',
      () {
        expect(
          at('usesmileid-sample-flutter://settings/licenses').link,
          Uri.parse('usesmileid-sample-flutter://settings/licenses'),
        );
        expect(
          at('usesmileid-sample-flutter://settings').link,
          Uri.parse('usesmileid-sample-flutter://settings'),
        );
      },
    );

    test('is a plain path as it came', () {
      expect(at('/verifications').link, Uri.parse('/verifications'));
    });
  });

  group('the arguments', () {
    test('are the plain defaults on a launch that carried none', () {
      expect(at('/').args.seedJobs, isFalse);
      expect(at('/').args.seedProfiles, isFalse);
      expect(at('/').args.probes, isFalse);
    });

    test('are read off the query of the launching link', () {
      final UseSmileIDSampleLaunch launch = at(
        'usesmileid-sample-flutter://products?seedJobs=true&seedProfiles=true',
      );

      expect(launch.args.seedJobs, isTrue);
      expect(launch.args.seedProfiles, isTrue);
      expect(launch.args.probes, isFalse);
    });

    // Anything but an explicit true is the default: a typo must not silently seed a partner's app
    // with made-up verifications.
    test('take only an explicit true', () {
      expect(at('/?seedJobs=1').args.seedJobs, isFalse);
      expect(at('/?seedJobs=yes').args.seedJobs, isFalse);
      expect(at('/?seedJobs=').args.seedJobs, isFalse);
      expect(at('/?seedJobs=TRUE').args.seedJobs, isTrue);
      expect(at('/?seedJobs= true ').args.seedJobs, isTrue);
    });
  });
}
