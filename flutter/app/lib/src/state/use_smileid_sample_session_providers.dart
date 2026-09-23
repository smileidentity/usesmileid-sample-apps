import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../status/use_smileid_sample_http_job_status_source.dart';

/// Where the token session is kept; the shell overrides this with the secure store.
final Provider<UseSmileIDSampleSessionRepository>
useSmileIDSampleSessionRepositoryProvider =
    Provider<UseSmileIDSampleSessionRepository>(
      (Ref ref) => UseSmileIDSampleMemorySessionRepository(),
    );

/// What the store held when the app started, read before the first frame.
final Provider<UseSmileIDSampleSessionRecord>
useSmileIDSampleStoredSessionProvider = Provider<UseSmileIDSampleSessionRecord>(
  (Ref ref) => const UseSmileIDSampleSessionRecord(),
);

/// The wall clock the deadline is read against; a test moves it without firing any timer.
final Provider<int Function()> useSmileIDSampleWallClockProvider =
    Provider<int Function()>(
      (Ref ref) =>
          () => DateTime.now().millisecondsSinceEpoch,
    );

/// The linked session or its ended marker, and the only writer of either.
final NotifierProvider<
  UseSmileIDSampleSessionNotifier,
  UseSmileIDSampleSessionRecord
>
useSmileIDSampleSessionProvider =
    NotifierProvider<
      UseSmileIDSampleSessionNotifier,
      UseSmileIDSampleSessionRecord
    >(UseSmileIDSampleSessionNotifier.new);

/// Holds the record, and retires the token the moment its deadline passes.
class UseSmileIDSampleSessionNotifier
    extends Notifier<UseSmileIDSampleSessionRecord> {
  Timer? _deadline;

  @override
  UseSmileIDSampleSessionRecord build() {
    ref.onDispose(() => _deadline?.cancel());
    final UseSmileIDSampleSessionRecord stored = ref.read(
      useSmileIDSampleStoredSessionProvider,
    );
    _schedule(stored.live);
    return stored;
  }

  /// Every write, in call order: an overlapping retire once landed a marker over a newer link.
  Future<void> _writes = Future<void>.value();

  /// Retires the live session when the wall clock is past its deadline; the timer alone misses a sleeping device.
  Future<void> checkDeadline() async {
    final UseSmileIDSampleTokenSession? live = state.live;
    if (live != null && live.hasExpired(_now())) {
      await _retire(live);
    }
  }

  /// Links a decoded session, replacing any live one or ended marker.
  Future<void> link(UseSmileIDSampleTokenSession session) =>
      _enqueue(() => _write(() => _repository.link(session)));

  /// Sign out: no ended marker, which would send the next run to the scanner.
  Future<void> clear() => _enqueue(() => _write(_repository.clear));

  /// Past the deadline the token is useless, so it goes; that a session ended stays.
  Future<void> _retire(
    UseSmileIDSampleTokenSession session,
  ) => _enqueue(() async {
    // Checked once earlier writes have landed, so a link made meanwhile is never retired.
    if (state.live != session) {
      return;
    }
    await _write(() => _repository.retire(session));
  });

  Future<void> _enqueue(Future<void> Function() write) {
    final Future<void> next = _writes.then((_) => write());
    _writes = next;
    return next;
  }

  Future<void> _write(
    Future<UseSmileIDSampleSessionRecord> Function() write,
  ) async {
    try {
      final UseSmileIDSampleSessionRecord record = await write();
      state = record;
      _schedule(record.live);
    } on Object {
      // The platform store can refuse a write; the record on screen stays the stored one.
    }
  }

  /// A cold start after expiry takes the same path, the timer firing at once.
  void _schedule(UseSmileIDSampleTokenSession? live) {
    _deadline?.cancel();
    _deadline = null;
    if (live == null) {
      return;
    }
    final int wait = live.expiresAtMillis - _now();
    _deadline = Timer(
      Duration(milliseconds: wait < 0 ? 0 : wait),
      () => unawaited(_retire(live)),
    );
  }

  UseSmileIDSampleSessionRepository get _repository =>
      ref.read(useSmileIDSampleSessionRepositoryProvider);

  int _now() => ref.read(useSmileIDSampleWallClockProvider)();
}

/// The wall clock, ticking once a second only while a session is live, so nothing else rebuilds on it.
final NotifierProvider<UseSmileIDSampleClockNotifier, int>
useSmileIDSampleClockProvider =
    NotifierProvider<UseSmileIDSampleClockNotifier, int>(
      UseSmileIDSampleClockNotifier.new,
    );

/// Starts and stops with the live session; the deadline is absolute, so a restart needs no recomputing.
class UseSmileIDSampleClockNotifier extends Notifier<int> {
  @override
  int build() {
    final bool live =
        ref.watch(
          useSmileIDSampleSessionProvider.select(
            (UseSmileIDSampleSessionRecord record) => record.live,
          ),
        ) !=
        null;
    final int Function() now = ref.read(useSmileIDSampleWallClockProvider);
    if (live) {
      final Timer tick = Timer.periodic(_tick, (_) {
        state = now();
        // Each tick also re-reads the deadline, which retries a retirement the store refused.
        unawaited(
          ref.read(useSmileIDSampleSessionProvider.notifier).checkDeadline(),
        );
      });
      ref.onDispose(tick.cancel);
    }
    return now();
  }
}

/// The run the expiry gate sent to the scanner, held on app state so no route carries continuation state.
final NotifierProvider<
  UseSmileIDSampleInterruptedRunNotifier,
  UseSmileIDSampleRunIntent?
>
useSmileIDSampleInterruptedRunProvider =
    NotifierProvider<
      UseSmileIDSampleInterruptedRunNotifier,
      UseSmileIDSampleRunIntent?
    >(UseSmileIDSampleInterruptedRunNotifier.new);

/// One pending run at most; the scanner claims it on arrival, so leaving drops it.
class UseSmileIDSampleInterruptedRunNotifier
    extends Notifier<UseSmileIDSampleRunIntent?> {
  @override
  UseSmileIDSampleRunIntent? build() => null;

  /// Hands a run to the scanner.
  void send(UseSmileIDSampleRunIntent intent) => state = intent;

  /// Drops [claimed] once the scanner has read it, leaving a run sent since then in place.
  void release(UseSmileIDSampleRunIntent? claimed) {
    if (state == claimed) {
      state = null;
    }
  }
}

/// Where a status refresh asks; a test overrides it so no refresh reaches a network.
final Provider<UseSmileIDSampleJobStatusSource>
useSmileIDSampleJobStatusSourceProvider =
    Provider<UseSmileIDSampleJobStatusSource>(
      (Ref ref) => UseSmileIDSampleHttpJobStatusSource(),
    );

/// The only place the environment is decided: the linked session owns it, and no session is sandbox.
bool useSmileIDSampleUseSandbox(UseSmileIDSampleTokenSession? session) =>
    session?.environment != UseSmileIDSampleEnvironment.production;

/// Tick once a second: the countdown's resolution.
const Duration _tick = Duration(seconds: 1);
