import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

import 'src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'src/data/use_smileid_sample_secure_profiles_repository.dart';
import 'src/data/use_smileid_sample_secure_session_repository.dart';
import 'src/flow/use_smileid_sample_flow_builder_config.dart';
import 'src/state/use_smileid_sample_providers.dart';
import 'src/state/use_smileid_sample_session_providers.dart';
import 'src/use_smileid_sample_app.dart';
import 'src/use_smileid_sample_launch.dart';
import 'src/use_smileid_sample_shell_extension.dart';

export 'src/use_smileid_sample_shell_extension.dart'
    show UseSmileIDSampleShellExtension;

/// Starts the app, with an SDK repo's [extension] in a source build; the store is read before the first frame.
Future<void> useSmileIDSampleBootstrap({
  UseSmileIDSampleShellExtension? extension,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 15 imposes edge to edge; earlier versions opt in here.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Once: the analyzers a flow registers follow the phone's mobile services.
  if (defaultTargetPlatform == TargetPlatform.android) {
    useSmileIDSampleMobileServices =
        await useSmileIDSamplePreferredMobileServices(
          UseSmileIDMobileServices().preferred,
        );
  }
  final UseSmileIDSamplePreferencesSettingsRepository settings =
      await UseSmileIDSamplePreferencesSettingsRepository.open();
  final UseSmileIDSampleSettings stored = await settings.read();
  final UseSmileIDSampleSecureSessionRepository sessions =
      UseSmileIDSampleSecureSessionRepository();
  final String route = PlatformDispatcher.instance.defaultRouteName;
  // Ahead of the read, so autostart finds the extension's session as if it had been scanned.
  final Object? failure = await useSmileIDSampleLaunchExtension(
    extension,
    route,
    sessions.link,
  );
  if (failure != null) {
    runApp(ErrorWidget(failure));
    return;
  }
  // Before the first frame, or the session card flashes in late.
  final UseSmileIDSampleSessionRecord session = await _readSession(sessions);
  final UseSmileIDSamplePreferencesJobsRepository jobs =
      await UseSmileIDSamplePreferencesJobsRepository.open();
  final UseSmileIDSampleSecureProfilesRepository profiles =
      await UseSmileIDSampleSecureProfilesRepository.open();
  // Once, before the first frame: a link delivered to a live app must never re-seed the arguments.
  final UseSmileIDSampleLaunch launch = UseSmileIDSampleLaunch(route);
  // Here, not in the provider, which re-seeded a just-removed row on every invalidation.
  await useSmileIDSampleApplyLaunch(launch.args, jobs);
  final ProviderContainer container = ProviderContainer(
    overrides: [
      useSmileIDSampleShellExtensionProvider.overrideWithValue(extension),
      useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(settings),
      useSmileIDSampleStoredSettingsProvider.overrideWithValue(stored),
      useSmileIDSampleJobsRepositoryProvider.overrideWithValue(jobs),
      useSmileIDSampleProfilesRepositoryProvider.overrideWithValue(profiles),
      useSmileIDSampleSessionRepositoryProvider.overrideWithValue(sessions),
      useSmileIDSampleStoredSessionProvider.overrideWithValue(session),
      useSmileIDSampleLaunchArgsOverride(launch.args),
    ],
  );
  // Eager, so a lapsed session retires before any screen draws.
  container.read(useSmileIDSampleSessionProvider);
  // The runner's SceneDelegate seeds a cold link as the initial route, so on iOS this listens only after an icon launch.
  if (defaultTargetPlatform == TargetPlatform.iOS && route == '/') {
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
      child: UseSmileIDSampleApp(initialLocation: launch.startLocation),
    ),
  );
}

/// A store that refuses the read yields no session, never a failed launch.
Future<UseSmileIDSampleSessionRecord> _readSession(
  UseSmileIDSampleSecureSessionRepository sessions,
) async {
  try {
    return await sessions.read();
  } on Object {
    return const UseSmileIDSampleSessionRecord();
  }
}
