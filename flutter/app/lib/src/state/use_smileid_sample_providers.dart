import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sample_ui/sample_ui.dart';

/// The launch arguments, overridden once at app start so automation needs no test-only build.
final Provider<UseSmileIDSampleLaunchArgs> useSmileIDSampleLaunchArgsProvider =
    Provider<UseSmileIDSampleLaunchArgs>(
      (Ref ref) => const UseSmileIDSampleLaunchArgs(),
    );

/// A cold link's arguments when the platform handed the link over after the first frame, as iOS does.
final NotifierProvider<
  UseSmileIDSampleColdLinkArgsNotifier,
  UseSmileIDSampleLaunchArgs?
>
useSmileIDSampleColdLinkArgsProvider =
    NotifierProvider<
      UseSmileIDSampleColdLinkArgsNotifier,
      UseSmileIDSampleLaunchArgs?
    >(UseSmileIDSampleColdLinkArgsNotifier.new);

/// Null until a cold link is adopted, which happens at most once per process.
class UseSmileIDSampleColdLinkArgsNotifier
    extends Notifier<UseSmileIDSampleLaunchArgs?> {
  @override
  UseSmileIDSampleLaunchArgs? build() => null;

  /// Takes the arguments of the link the process was launched at.
  void adopt(UseSmileIDSampleLaunchArgs args) => state = args;
}

/// The startup arguments, replaced by a late-delivered cold link's once it arrives.
Override useSmileIDSampleLaunchArgsOverride(
  UseSmileIDSampleLaunchArgs startup,
) => useSmileIDSampleLaunchArgsProvider.overrideWith(
  (Ref ref) => ref.watch(useSmileIDSampleColdLinkArgsProvider) ?? startup,
);

/// Where the switches are kept; the shell overrides this with the store that survives a restart.
final Provider<UseSmileIDSampleSettingsRepository>
useSmileIDSampleSettingsRepositoryProvider =
    Provider<UseSmileIDSampleSettingsRepository>(
      (Ref ref) => UseSmileIDSampleMemorySettingsRepository(),
    );

/// What the store held when the app started.
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
    final UseSmileIDSampleSettings previous = state;
    try {
      state = await ref
          .read(useSmileIDSampleSettingsRepositoryProvider)
          .setSetting(setting, enabled);
    } on Object {
      // The platform store can refuse a write.
      state = previous;
    }
  }
}

/// Where the profiles are kept; the shell overrides this with the store that survives a restart.
final Provider<UseSmileIDSampleProfilesRepository>
useSmileIDSampleProfilesRepositoryProvider =
    Provider<UseSmileIDSampleProfilesRepository>(
      (Ref ref) => UseSmileIDSampleMemoryProfilesRepository(),
    );

/// The profiles the app can act as: the stored ones, or the fixtures when the launch seeds them.
final NotifierProvider<
  UseSmileIDSampleProfilesNotifier,
  UseSmileIDSampleProfiles
>
useSmileIDSampleProfilesProvider =
    NotifierProvider<
      UseSmileIDSampleProfilesNotifier,
      UseSmileIDSampleProfiles
    >(UseSmileIDSampleProfilesNotifier.new);

/// Holds the profiles, tells their readers when they change, and stores every change unless seeded.
class UseSmileIDSampleProfilesNotifier
    extends Notifier<UseSmileIDSampleProfiles> {
  @override
  UseSmileIDSampleProfiles build() => UseSmileIDSampleProfiles.forLaunch(
    ref.watch(useSmileIDSampleLaunchArgsProvider),
    stored: ref.read(useSmileIDSampleProfilesRepositoryProvider).read(),
  );

  /// Switches the active profile.
  void setActive(String id) => _change(() => state.setActive(id));

  /// Adds a profile and returns it.
  UseSmileIDSampleProfile add({
    required String organisation,
    UseSmileIDSampleUserDetails defaults = const UseSmileIDSampleUserDetails(),
    bool activate = false,
  }) {
    late UseSmileIDSampleProfile created;
    _change(
      () => created = state.add(
        organisation: organisation,
        defaults: defaults,
        activate: activate,
      ),
    );
    return created;
  }

  /// Replaces the given parts of a profile.
  void update(
    String id, {
    String? organisation,
    UseSmileIDSampleUserDetails? defaults,
    String? callbackUrl,
  }) => _change(
    () => state.update(
      id,
      organisation: organisation,
      defaults: defaults,
      callbackUrl: callbackUrl,
    ),
  );

  /// Deletes a profile; the active one hands over to the first left.
  void delete(String id) => _change(() => state.delete(id));

  /// Sign out: every profile goes.
  void clear() => _change(state.clear);

  /// Continue's write-back from the details form.
  void keep(
    UseSmileIDSampleUserDetails details, {
    required String organisation,
    required UseSmileIDSampleUserDetailsRequirement requirement,
  }) => _change(
    () => state.keep(
      details,
      organisation: organisation,
      requirement: requirement,
    ),
  );

  /// Forgets the just-created marker, which is not stored.
  void clearLastCreated() {
    state.clearLastCreated();
    ref.notifyListeners();
  }

  void _change(void Function() change) {
    final String before = UseSmileIDSampleProfilesCodec.encode(state);
    change();
    ref.notifyListeners();
    // Nothing moved, so nothing is written, as on Android and iOS.
    if (UseSmileIDSampleProfilesCodec.encode(state) == before) {
      return;
    }
    // Fixtures are never stored: an automation run must not leave made-up people behind.
    if (!ref.read(useSmileIDSampleLaunchArgsProvider).seedProfiles) {
      unawaited(
        ref.read(useSmileIDSampleProfilesRepositoryProvider).write(state),
      );
    }
  }
}

/// Where the verifications are kept; the shell overrides this with the store that survives a restart.
final Provider<UseSmileIDSampleJobsRepository>
useSmileIDSampleJobsRepositoryProvider =
    Provider<UseSmileIDSampleJobsRepository>(
      (Ref ref) => UseSmileIDSampleMemoryJobsRepository(),
    );

/// The stored verifications, null until the store has answered.
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
  Future<List<UseSmileIDSampleJob>> build() async =>
      await ref.watch(useSmileIDSampleJobsRepositoryProvider).read() ??
      const <UseSmileIDSampleJob>[];

  /// Records a verification, which is the first thing a finished run does.
  Future<void> addJob(UseSmileIDSampleJob job) async {
    await ref.read(useSmileIDSampleJobsRepositoryProvider).add(job);
    ref.invalidateSelf();
  }

  /// Refreshes one row's status, returning what the store decided; null means one is already running.
  Future<UseSmileIDSampleStatusRefresh?> refreshJob({
    required String jobId,
    required UseSmileIDSampleRefreshSession? session,
    required int nowMillis,
    required UseSmileIDSampleJobStatusSource source,
  }) async {
    final UseSmileIDSampleStatusRefresh? outcome = await ref
        .read(useSmileIDSampleJobsRepositoryProvider)
        .refresh(
          jobId: jobId,
          session: session,
          nowMillis: nowMillis,
          source: source,
        );
    if (outcome is UseSmileIDSampleStatusUpdated) {
      ref.invalidateSelf();
    }
    return outcome;
  }

  /// Hides rows and returns how many were taken, which is what the confirmation reports.
  Future<int> removeJobs(Set<String> ids) async {
    final int taken = await ref
        .read(useSmileIDSampleJobsRepositoryProvider)
        .remove(ids);
    if (taken > 0) {
      ref.invalidateSelf();
    }
    return taken;
  }

  /// Puts the last removal back.
  Future<void> undoRemoval() async {
    await ref.read(useSmileIDSampleJobsRepositoryProvider).undoRemove();
    ref.invalidateSelf();
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

/// Which rows are being picked, and whether picking is on at all.
class UseSmileIDSampleSelection {
  /// A selection with nothing picked, which is what entering select mode starts from.
  const UseSmileIDSampleSelection({
    this.active = false,
    this.ids = const <String>{},
  });

  /// Whether the rows are being picked rather than opened.
  final bool active;

  /// The ids picked so far.
  final Set<String> ids;
}

/// The verifications list's select mode, held above the screen because the BAR lives in the shell.
final NotifierProvider<
  UseSmileIDSampleSelectionNotifier,
  UseSmileIDSampleSelection
>
useSmileIDSampleSelectionProvider =
    NotifierProvider<
      UseSmileIDSampleSelectionNotifier,
      UseSmileIDSampleSelection
    >(UseSmileIDSampleSelectionNotifier.new);

/// Owns select mode and the picked ids.
class UseSmileIDSampleSelectionNotifier
    extends Notifier<UseSmileIDSampleSelection> {
  @override
  UseSmileIDSampleSelection build() => const UseSmileIDSampleSelection();

  /// Enters or leaves select mode, clearing the picks on the way IN rather than on the way out, so
  /// the bar still reads its count while it animates away.
  void setActive(bool on) => state = on
      ? const UseSmileIDSampleSelection(active: true)
      : UseSmileIDSampleSelection(ids: state.ids);

  /// Picks or unpicks one row.
  void select(String jobId, bool picked) => state = UseSmileIDSampleSelection(
    active: state.active,
    ids: <String>{
      ...state.ids.where((String id) => id != jobId),
      if (picked) jobId,
    },
  );
}

/// How many rows the last removal took, for as long as the confirmation stands.
final NotifierProvider<UseSmileIDSampleRemovalNoticeNotifier, int?>
useSmileIDSampleRemovalNoticeProvider =
    NotifierProvider<UseSmileIDSampleRemovalNoticeNotifier, int?>(
      UseSmileIDSampleRemovalNoticeNotifier.new,
    );

/// Shows a removal confirmation for its window, then withdraws it.
class UseSmileIDSampleRemovalNoticeNotifier extends Notifier<int?> {
  Timer? _timer;

  @override
  int? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  /// Shows a confirmation for [count] rows, restarting the window if one already stands.
  void show(int count) {
    _timer?.cancel();
    state = count;
    _timer = Timer(_window, dismiss);
  }

  /// Only automation passes one; without it this is the product's window.
  Duration get _window {
    final int? seconds = ref
        .read(useSmileIDSampleLaunchArgsProvider)
        .noticeWindow;
    return seconds == null
        ? useSmileIDSampleNoticeWindow
        : Duration(seconds: seconds);
  }

  /// Withdraws the confirmation, which is what taking its action also does.
  void dismiss() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }
}

/// How long a transient confirmation stands, which the twin sets at five seconds.
const Duration useSmileIDSampleNoticeWindow = Duration(seconds: 5);

/// Which scenarios a run carries, seeded from the launch arguments and changed by the drawer.
final NotifierProvider<
  UseSmileIDSampleScenarioNotifier,
  UseSmileIDSampleScenarioSelection
>
useSmileIDSampleScenarioProvider =
    NotifierProvider<
      UseSmileIDSampleScenarioNotifier,
      UseSmileIDSampleScenarioSelection
    >(UseSmileIDSampleScenarioNotifier.new);

/// The flow and theme scenarios a run carries, which are one each.
@immutable
class UseSmileIDSampleScenarioSelection {
  /// Both default to the ship state, which is what a launch with no arguments gets.
  const UseSmileIDSampleScenarioSelection({
    this.scenario = UseSmileIDSampleScenario.normal,
    this.theme = UseSmileIDSampleThemeScenario.brandDefault,
  });

  /// The active flow scenario.
  final UseSmileIDSampleScenario scenario;

  /// The active theme scenario.
  final UseSmileIDSampleThemeScenario theme;
}

/// Seeds from the launch arguments so a flow can start in a scenario without tapping the drawer.
class UseSmileIDSampleScenarioNotifier
    extends Notifier<UseSmileIDSampleScenarioSelection> {
  @override
  UseSmileIDSampleScenarioSelection build() {
    final UseSmileIDSampleLaunchArgs args = ref.watch(
      useSmileIDSampleLaunchArgsProvider,
    );
    return UseSmileIDSampleScenarioSelection(
      scenario: args.scenario,
      theme: args.theme,
    );
  }

  /// Chooses a flow scenario.
  void selectScenario(UseSmileIDSampleScenario scenario) => state =
      UseSmileIDSampleScenarioSelection(scenario: scenario, theme: state.theme);

  /// Chooses a theme scenario.
  void selectTheme(UseSmileIDSampleThemeScenario theme) => state =
      UseSmileIDSampleScenarioSelection(scenario: state.scenario, theme: theme);
}

/// The third-party notices Flutter's build step collected, read once per launch.
final FutureProvider<UseSmileIDSampleLicenses>
useSmileIDSampleLicensesProvider = FutureProvider<UseSmileIDSampleLicenses>(
  (Ref ref) => UseSmileIDSampleLicenses.bundled(),
);
