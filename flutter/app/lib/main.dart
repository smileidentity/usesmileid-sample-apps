import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import 'src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'src/state/use_smileid_sample_providers.dart';
import 'src/use_smileid_sample_app.dart';
import 'src/use_smileid_sample_launch.dart';

/// Reads the store BEFORE the first frame, or the default appearance flashes before the saved one.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15 imposes edge to edge; earlier versions opt in here.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final UseSmileIDSamplePreferencesSettingsRepository settings =
      await UseSmileIDSamplePreferencesSettingsRepository.open();
  final UseSmileIDSampleSettings stored = await settings.read();
  final UseSmileIDSamplePreferencesJobsRepository jobs =
      await UseSmileIDSamplePreferencesJobsRepository.open();
  // Read BEFORE the first frame and exactly once, which is the whole of the cold-start rule: a
  // link delivered to a live app must never re-seed the arguments.
  final UseSmileIDSampleLaunch launch = UseSmileIDSampleLaunch(
    PlatformDispatcher.instance.defaultRouteName,
  );
  // Once, before the first frame: a seed inside the provider re-ran on every invalidation and put
  // a just-removed row back. Idempotent by id, so a second seeded launch adds nothing.
  await useSmileIDSampleApplyLaunch(launch.args, jobs);
  final ProviderContainer container = ProviderContainer(
    overrides: [
      useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(settings),
      useSmileIDSampleStoredSettingsProvider.overrideWithValue(stored),
      useSmileIDSampleJobsRepositoryProvider.overrideWithValue(jobs),
      useSmileIDSampleLaunchArgsOverride(launch.args),
    ],
  );
  // iOS's scene lifecycle launches at '/' and pushes the link after the first frame; Android never does.
  if (defaultTargetPlatform == TargetPlatform.iOS &&
      PlatformDispatcher.instance.defaultRouteName == '/') {
    UseSmileIDSampleColdLink(
      onLink: (Uri link) async {
        final UseSmileIDSampleLaunchArgs args =
            UseSmileIDSampleLaunchArgs.fromUri(link);
        await useSmileIDSampleApplyLaunch(args, jobs);
        container
            .read(useSmileIDSampleColdLinkArgsProvider.notifier)
            .adopt(args);
        container.invalidate(useSmileIDSampleJobsProvider);
      },
    ).listen();
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: UseSmileIDSampleApp(initialLocation: launch.location),
    ),
  );
}
