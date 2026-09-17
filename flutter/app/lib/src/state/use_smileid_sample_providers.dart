import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

/// The launch arguments, overridden once at app start so automation needs no test-only build.
final Provider<UseSmileIDSampleLaunchArgs> useSmileIDSampleLaunchArgsProvider =
    Provider<UseSmileIDSampleLaunchArgs>(
      (Ref ref) => const UseSmileIDSampleLaunchArgs(),
    );

/// Where the switches are kept; the shell overrides this with the store that survives a restart.
final Provider<UseSmileIDSampleSettingsRepository>
useSmileIDSampleSettingsRepositoryProvider =
    Provider<UseSmileIDSampleSettingsRepository>(
      (Ref ref) => UseSmileIDSampleMemorySettingsRepository(),
    );

/// What the store held when the app started.
///
/// Overridden with a value already read, so the first frame is the stored appearance rather than
/// the default one, which would flash light before it settled dark (R9's cold start).
final Provider<UseSmileIDSampleSettings>
useSmileIDSampleStoredSettingsProvider = Provider<UseSmileIDSampleSettings>(
  (Ref ref) => const UseSmileIDSampleSettings(),
);

/// The six switches, and the only writer of them.
final NotifierProvider<
  UseSmileIDSampleSettingsNotifier,
  UseSmileIDSampleSettings
>
useSmileIDSampleSettingsProvider =
    NotifierProvider<
      UseSmileIDSampleSettingsNotifier,
      UseSmileIDSampleSettings
    >(UseSmileIDSampleSettingsNotifier.new);

/// Reads the stored settings, and writes every change back through the repository.
class UseSmileIDSampleSettingsNotifier
    extends Notifier<UseSmileIDSampleSettings> {
  @override
  UseSmileIDSampleSettings build() =>
      ref.read(useSmileIDSampleStoredSettingsProvider);

  /// Applies one switch, taking the stored result rather than assuming it, because the capture
  /// mutex can turn the other one off on the way past.
  Future<void> setSetting(UseSmileIDSampleSetting setting, bool enabled) async {
    state = await ref
        .read(useSmileIDSampleSettingsRepositoryProvider)
        .setSetting(setting, enabled);
  }
}

/// The profiles the app can act as, seeded from the launch arguments.
final NotifierProvider<
  UseSmileIDSampleProfilesNotifier,
  UseSmileIDSampleProfiles
>
useSmileIDSampleProfilesProvider =
    NotifierProvider<
      UseSmileIDSampleProfilesNotifier,
      UseSmileIDSampleProfiles
    >(UseSmileIDSampleProfilesNotifier.new);

/// Holds the store and tells its readers when it has changed.
///
/// The store is mutable and keeps its identity across a switch, so a new state object would say
/// nothing; this notifies instead, rather than duplicating the store's rules in a second shape.
class UseSmileIDSampleProfilesNotifier
    extends Notifier<UseSmileIDSampleProfiles> {
  @override
  UseSmileIDSampleProfiles build() => UseSmileIDSampleProfiles.forLaunch(
    ref.watch(useSmileIDSampleLaunchArgsProvider),
  );

  /// Switches the active profile.
  void setActive(String id) {
    state.setActive(id);
    ref.notifyListeners();
  }

  /// Adds a profile and returns it.
  UseSmileIDSampleProfile add({
    required String organisation,
    required String person,
    UseSmileIDSampleUserDetails defaults = const UseSmileIDSampleUserDetails(),
  }) {
    final UseSmileIDSampleProfile created = state.add(
      organisation: organisation,
      person: person,
      defaults: defaults,
    );
    ref.notifyListeners();
    return created;
  }

  /// Saves a profile's form defaults.
  void setDefaults(String id, UseSmileIDSampleUserDetails defaults) {
    state.setDefaults(id, defaults);
    ref.notifyListeners();
  }

  /// Forgets the just-created marker.
  void clearLastCreated() {
    state.clearLastCreated();
    ref.notifyListeners();
  }
}

/// Where the verifications are kept; the shell overrides this with the store that survives a restart.
final Provider<UseSmileIDSampleJobsRepository>
useSmileIDSampleJobsRepositoryProvider =
    Provider<UseSmileIDSampleJobsRepository>(
      (Ref ref) => UseSmileIDSampleMemoryJobsRepository(),
    );

/// The stored verifications, null until the store has answered.
///
/// Asynchronous on purpose: the list's third state is NOT LOADED YET, and collapsing it to an
/// empty list makes a first frame claim there is nothing stored before anything has been read.
final AsyncNotifierProvider<
  UseSmileIDSampleJobsNotifier,
  List<UseSmileIDSampleJob>
>
useSmileIDSampleJobsProvider =
    AsyncNotifierProvider<
      UseSmileIDSampleJobsNotifier,
      List<UseSmileIDSampleJob>
    >(UseSmileIDSampleJobsNotifier.new);

/// Reads the store once, seeding the fixtures first when the launch argument asks for them.
class UseSmileIDSampleJobsNotifier
    extends AsyncNotifier<List<UseSmileIDSampleJob>> {
  @override
  Future<List<UseSmileIDSampleJob>> build() async {
    final UseSmileIDSampleJobsRepository jobs = ref.watch(
      useSmileIDSampleJobsRepositoryProvider,
    );
    if (ref.watch(useSmileIDSampleLaunchArgsProvider).seedJobs) {
      await jobs.seedFixtures(DateTime.now().millisecondsSinceEpoch);
    }
    return await jobs.read() ?? const <UseSmileIDSampleJob>[];
  }
}

/// The active filter chip, which is screen state rather than stored state.
final NotifierProvider<
  UseSmileIDSampleJobFilterNotifier,
  UseSmileIDSampleJobFilter
>
useSmileIDSampleJobFilterProvider =
    NotifierProvider<
      UseSmileIDSampleJobFilterNotifier,
      UseSmileIDSampleJobFilter
    >(UseSmileIDSampleJobFilterNotifier.new);

/// Holds which chip is active.
class UseSmileIDSampleJobFilterNotifier
    extends Notifier<UseSmileIDSampleJobFilter> {
  @override
  UseSmileIDSampleJobFilter build() => UseSmileIDSampleJobFilter.all;

  /// Switches the active chip.
  void select(UseSmileIDSampleJobFilter filter) => state = filter;
}
