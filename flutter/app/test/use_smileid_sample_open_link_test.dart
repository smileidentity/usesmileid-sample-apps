import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:usesmileid_sample_flutter/src/screens/use_smileid_sample_settings_tab.dart';

void main() {
  final List<(Uri, LaunchMode)> launched = <(Uri, LaunchMode)>[];
  Future<bool> record(
    Uri url, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    launched.add((url, mode));
    return true;
  }

  setUp(launched.clear);

  test(
    'every link row with a url opens it, in app unless the row says otherwise',
    () async {
      final List<UseSmileIDSampleNavRow> rows = useSmileIDSampleNavRows
          .where((UseSmileIDSampleNavRow row) => row.url != null)
          .toList();
      expect(rows, isNotEmpty);
      for (final UseSmileIDSampleNavRow row in rows) {
        await useSmileIDSampleOpenLink(
          Uri.parse(row.url!),
          inApp: row.opensInApp,
          launch: record,
        );
      }
      expect(launched, <(Uri, LaunchMode)>[
        for (final UseSmileIDSampleNavRow row in rows)
          (
            Uri.parse(row.url!),
            row.opensInApp
                ? LaunchMode.inAppBrowserView
                : LaunchMode.externalApplication,
          ),
      ]);
    },
  );

  test(
    'a launch that throws is swallowed rather than crashing the tap',
    () async {
      await expectLater(
        useSmileIDSampleOpenLink(
          Uri.parse('https://usesmileid.com'),
          inApp: true,
          launch: (Uri url, {LaunchMode mode = LaunchMode.platformDefault}) =>
              throw StateError('no browser'),
        ),
        completes,
      );
    },
  );

  test(
    'an in-app link nothing can show falls back to the system browser',
    () async {
      final List<LaunchMode> modes = <LaunchMode>[];
      await useSmileIDSampleOpenLink(
        Uri.parse('https://usesmileid.com'),
        inApp: true,
        launch:
            (Uri url, {LaunchMode mode = LaunchMode.platformDefault}) async {
              modes.add(mode);
              return mode == LaunchMode.externalApplication;
            },
      );
      expect(modes, <LaunchMode>[
        LaunchMode.inAppBrowserView,
        LaunchMode.externalApplication,
      ]);
    },
  );
}
