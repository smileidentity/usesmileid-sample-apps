import 'dart:convert';

import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The verifications that survive a restart.
///
/// One JSON array under one key, rather than a database: the twin uses Room, but this list is the
/// design's eleven plus whatever one device session produces, and a database would be a dependency
/// and a migration story for a sample that has neither query nor scale to justify them.
class UseSmileIDSamplePreferencesJobsRepository
    implements UseSmileIDSampleJobsRepository {
  /// Takes the already-opened preferences, so a caller cannot forget to await them.
  const UseSmileIDSamplePreferencesJobsRepository(this._preferences);

  final SharedPreferences _preferences;

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

  List<UseSmileIDSampleJob> _stored() {
    final String? raw = _preferences.getString(useSmileIDSampleJobsKey);
    if (raw == null) {
      return const <UseSmileIDSampleJob>[];
    }
    // A store this build cannot read is treated as no store: a sample must not refuse to start
    // because an older write left a shape it no longer understands.
    try {
      return <UseSmileIDSampleJob>[
        for (final Object? each in jsonDecode(raw) as List<Object?>)
          UseSmileIDSampleJob.fromJson(each! as Map<String, Object?>),
      ]..sort(
        (UseSmileIDSampleJob a, UseSmileIDSampleJob b) =>
            b.createdAtMillis.compareTo(a.createdAtMillis),
      );
    } on Object {
      return const <UseSmileIDSampleJob>[];
    }
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
