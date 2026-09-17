import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import 'src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'src/state/use_smileid_sample_providers.dart';
import 'src/use_smileid_sample_app.dart';

/// Opens the store and reads it BEFORE the first frame, so a cold start and a restored start show
/// the same tree; reading it after would flash the default appearance before settling on the saved
/// one, which is the defect R9's cold-start rule exists for.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final UseSmileIDSamplePreferencesSettingsRepository settings =
      await UseSmileIDSamplePreferencesSettingsRepository.open();
  final UseSmileIDSampleSettings stored = await settings.read();
  final UseSmileIDSamplePreferencesJobsRepository jobs =
      await UseSmileIDSamplePreferencesJobsRepository.open();
  runApp(
    ProviderScope(
      overrides: [
        useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(settings),
        useSmileIDSampleStoredSettingsProvider.overrideWithValue(stored),
        useSmileIDSampleJobsRepositoryProvider.overrideWithValue(jobs),
      ],
      child: const UseSmileIDSampleApp(),
    ),
  );
}
