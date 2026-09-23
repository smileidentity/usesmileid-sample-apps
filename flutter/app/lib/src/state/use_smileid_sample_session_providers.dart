import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../status/use_smileid_sample_http_job_status_source.dart';

/// Where the token session is kept.
final Provider<UseSmileIDSampleSessionRepository>
useSmileIDSampleSessionRepositoryProvider =
    Provider<UseSmileIDSampleSessionRepository>(
      (Ref ref) => UseSmileIDSampleMemorySessionRepository(),
    );

/// The session record read before the first frame.
final Provider<UseSmileIDSampleSessionRecord>
useSmileIDSampleStoredSessionProvider = Provider<UseSmileIDSampleSessionRecord>(
  (Ref ref) => const UseSmileIDSampleSessionRecord(),
);

/// The wall clock deadlines are read against.
final Provider<int Function()> useSmileIDSampleWallClockProvider =
    Provider<int Function()>(
      (Ref ref) =>
          () => DateTime.now().millisecondsSinceEpoch,
    );

/// The linked session or its ended marker.
final NotifierProvider<
  UseSmileIDSampleSessionNotifier,
  UseSmileIDSampleSessionRecord
>
useSmileIDSampleSessionProvider =
    NotifierProvider<
      UseSmileIDSampleSessionNotifier,
      UseSmileIDSampleSessionRecord
    >(UseSmileIDSampleSessionNotifier.new);

/// Holds the record and retires the token at its deadline.
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

  /// Every write, serialised in call order.
  Future<void> _writes = Future<void>.value();

  /// Retires the live session once the wall clock passes its deadline.
  Future<void> checkDeadline() async {
    final UseSmileIDSampleTokenSession? live = state.live;
    if (live != null && live.hasExpired(_now())) {
      await _retire(live);
    }
  }

  /// Links a decoded session, live for this run even if the store refuses it.
  Future<void> link(UseSmileIDSampleTokenSession session) {
    state = UseSmileIDSampleSessionRecord(live: session);
    _schedule(session);
    return _enqueue(() => _write(() => _repository.link(session)));
  }

  /// Sign out: clears the session without an ended marker.
  Future<void> clear() {
    state = const UseSmileIDSampleSessionRecord();
    _schedule(null);
    return _enqueue(() => _write(_repository.clear));
  }

  /// Retires [session] if it is still the live one.
  Future<void> _retire(UseSmileIDSampleTokenSession session) =>
      _enqueue(() async {
        // Re-checked at its turn, so a link made meanwhile is never retired.
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
      // The platform store can refuse a write.
    }
  }

  /// Arms the deadline timer for [live].
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

/// The wall clock, ticking once a second while a session is live.
final NotifierProvider<UseSmileIDSampleClockNotifier, int>
useSmileIDSampleClockProvider =
    NotifierProvider<UseSmileIDSampleClockNotifier, int>(
      UseSmileIDSampleClockNotifier.new,
    );

/// Ticks while a session is live, re-checking its deadline.
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
        unawaited(
          ref.read(useSmileIDSampleSessionProvider.notifier).checkDeadline(),
        );
      });
      ref.onDispose(tick.cancel);
    }
    return now();
  }
}

/// The run the expiry gate sent to the scanner.
final NotifierProvider<
  UseSmileIDSampleInterruptedRunNotifier,
  UseSmileIDSampleRunIntent?
>
useSmileIDSampleInterruptedRunProvider =
    NotifierProvider<
      UseSmileIDSampleInterruptedRunNotifier,
      UseSmileIDSampleRunIntent?
    >(UseSmileIDSampleInterruptedRunNotifier.new);

/// Holds at most one pending run.
class UseSmileIDSampleInterruptedRunNotifier
    extends Notifier<UseSmileIDSampleRunIntent?> {
  @override
  UseSmileIDSampleRunIntent? build() => null;

  /// Hands a run to the scanner.
  void send(UseSmileIDSampleRunIntent intent) => state = intent;

  /// Drops [claimed], leaving any run sent since.
  void release(UseSmileIDSampleRunIntent? claimed) {
    if (state == claimed) {
      state = null;
    }
  }
}

/// Where a status refresh asks.
final Provider<UseSmileIDSampleJobStatusSource>
useSmileIDSampleJobStatusSourceProvider =
    Provider<UseSmileIDSampleJobStatusSource>(
      (Ref ref) => UseSmileIDSampleHttpJobStatusSource(),
    );

/// Whether a run goes to sandbox: only a production session says otherwise.
bool useSmileIDSampleUseSandbox(UseSmileIDSampleTokenSession? session) =>
    session?.environment != UseSmileIDSampleEnvironment.production;

/// The countdown's resolution.
const Duration _tick = Duration(seconds: 1);
