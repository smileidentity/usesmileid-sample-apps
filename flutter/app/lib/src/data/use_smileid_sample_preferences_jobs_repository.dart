import 'dart:convert';

import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The verifications that survive a restart.
class UseSmileIDSamplePreferencesJobsRepository
    with UseSmileIDSampleJobRefreshMixin
    implements UseSmileIDSampleJobsRepository {
  /// Takes the already-opened preferences, so a caller cannot forget to await them.
  UseSmileIDSamplePreferencesJobsRepository(this._preferences);

  final SharedPreferences _preferences;

  /// The last batch taken, per store and in memory: an undo must not outlive the process or leak between tests.
  List<UseSmileIDSampleJob> _lastRemoved = const <UseSmileIDSampleJob>[];

  /// Opens the store, which is done once before the first frame.
  static Future<UseSmileIDSamplePreferencesJobsRepository> open() async =>
      UseSmileIDSamplePreferencesJobsRepository(
        await SharedPreferences.getInstance(),
      );

  @override
  Future<List<UseSmileIDSampleJob>?> read() async => _stored();

  @override
  Future<void> seedFixtures(int nowMillis) async {
    final List<UseSmileIDSampleJob> stored = _stored();
    final Set<String> ids = stored.map((UseSmileIDSampleJob j) => j.id).toSet();
    // Idempotent by id, like the twin's insert-or-ignore: a second seeded launch must not double
    // every row, and a device suite seeds on every arm.
    await _write(<UseSmileIDSampleJob>[
      ...stored,
      ...useSmileIDSampleJobFixtures(
        nowMillis,
      ).where((UseSmileIDSampleJob job) => !ids.contains(job.id)),
    ]);
  }

  @override
  Future<int> remove(Set<String> ids) async {
    final List<UseSmileIDSampleJob> stored = _stored();
    final List<UseSmileIDSampleJob> taken = stored
        .where((UseSmileIDSampleJob job) => ids.contains(job.id))
        .toList();
    // An id that matched nothing returns early rather than clearing the undo: a no-op must not
    // spend a still-undoable batch.
    if (taken.isEmpty) {
      return 0;
    }
    _lastRemoved = taken;
    await _write(
      stored.where((UseSmileIDSampleJob job) => !ids.contains(job.id)).toList(),
    );
    return taken.length;
  }

  @override
  Future<void> undoRemove() async {
    if (_lastRemoved.isEmpty) {
      return;
    }
    await _write(<UseSmileIDSampleJob>[..._stored(), ..._lastRemoved]);
    _lastRemoved = const <UseSmileIDSampleJob>[];
  }

  @override
  Future<void> add(UseSmileIDSampleJob job) async {
    final List<UseSmileIDSampleJob> stored = _stored();
    if (stored.any((UseSmileIDSampleJob each) => each.id == job.id)) {
      return;
    }
    await _write(<UseSmileIDSampleJob>[...stored, job]);
  }

  @override
  Future<UseSmileIDSampleJob?> find(String jobId) async {
    for (final UseSmileIDSampleJob job in _stored()) {
      if (job.id == jobId) {
        return job;
      }
    }
    return null;
  }

  @override
  Future<bool> applyStatus({
    required String jobId,
    required UseSmileIDSampleStatus status,
    required String message,
    required int httpStatus,
  }) async {
    // Read and derive with no await between the two: a remove landing in that window is already
    // absent from what this writes, where a list captured earlier would resurrect the row.
    final List<UseSmileIDSampleJob> stored = _stored();
    final int at = stored.indexWhere(
      (UseSmileIDSampleJob job) => job.id == jobId,
    );
    if (at < 0) {
      return false;
    }
    final List<UseSmileIDSampleJob> next = List<UseSmileIDSampleJob>.of(stored);
    next[at] = next[at].withStatus(
      status: status,
      message: message,
      httpStatus: httpStatus,
    );
    await _write(next);
    return true;
  }

  List<UseSmileIDSampleJob> _stored() {
    final String? raw = _preferences.getString(useSmileIDSampleJobsKey);
    if (raw == null) {
      return const <UseSmileIDSampleJob>[];
    }
    // A store this build cannot read is treated as no store: a sample must not refuse to start
    // because an older write left a shape it no longer understands.
    final List<Object?> rows;
    try {
      rows = jsonDecode(raw) as List<Object?>;
    } on Object {
      return const <UseSmileIDSampleJob>[];
    }
    return <UseSmileIDSampleJob>[
      for (final Object? each in rows)
        // Per row, not per store: one row this build cannot read must not take the history with it.
        if (each is Map<String, Object?>) ?UseSmileIDSampleJob.fromStored(each),
    ]..sort(
      (UseSmileIDSampleJob a, UseSmileIDSampleJob b) =>
          b.createdAtMillis.compareTo(a.createdAtMillis),
    );
  }

  Future<void> _write(List<UseSmileIDSampleJob> jobs) => _preferences.setString(
    useSmileIDSampleJobsKey,
    jsonEncode(<Object>[
      for (final UseSmileIDSampleJob job in jobs) job.toJson(),
    ]),
  );
}

/// The key the stored verifications live under.
const String useSmileIDSampleJobsKey = 'jobs';
