import 'package:flutter_test/flutter_test.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_launch.dart';

/// The cold-start link: where it opens, and what arguments it carried.
void main() {
  UseSmileIDSampleLaunch at(String route) => UseSmileIDSampleLaunch(route);

  group('the location', () {
    test('is the start destination when the app was opened from the icon', () {
      expect(at('/').location, '/products');
    });

    // The defect this exists for, measured on a device: a custom-scheme link arrives WHOLE, and
    // go_router matches on the path, so handing it over unchanged lands on the not-found page.
    // The observed failure was 'no routes for location: usesmileid-sample-flutter://settings/'.
    test('folds a custom scheme and its host back into a path', () {
      expect(at('usesmileid-sample-flutter://settings').location, '/settings');
      expect(at('usesmileid-sample-flutter://settings/').location, '/settings');
    });

    test('keeps the segments under the host, which carry the arguments', () {
      expect(
        at('usesmileid-sample-flutter://verifications/job_01').location,
        '/verifications/job_01',
      );
      expect(
        at('usesmileid-sample-flutter://settings/licenses').location,
        '/settings/licenses',
      );
    });

    test('leaves a plain path alone', () {
      expect(at('/verifications').location, '/verifications');
    });

    test('drops the query, which is arguments rather than a destination', () {
      expect(
        at('usesmileid-sample-flutter://verifications?seedJobs=true').location,
        '/verifications',
      );
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
