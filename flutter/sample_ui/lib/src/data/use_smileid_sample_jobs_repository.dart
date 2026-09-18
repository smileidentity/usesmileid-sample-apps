import '../model/use_smileid_sample_job.dart';
import '../model/use_smileid_sample_product.dart';
import '../model/use_smileid_sample_status.dart';

/// Where the verifications are kept, so the screen never knows what is doing the keeping.
abstract interface class UseSmileIDSampleJobsRepository {
  /// Every stored job, newest first, or null while the store has not answered.
  Future<List<UseSmileIDSampleJob>?> read();

  /// Adds the design's eleven, ignoring any whose id is already stored.
  Future<void> seedFixtures(int nowMillis);

  /// The count is what was TAKEN: an id matching nothing must not spend a still-undoable batch.
  Future<int> remove(Set<String> ids);

  /// Puts the last removal back, once. A second call restores nothing.
  Future<void> undoRemove();
}

/// Jobs that live as long as the process, which is what a test and a preview want.
class UseSmileIDSampleMemoryJobsRepository
    implements UseSmileIDSampleJobsRepository {
  /// [initial] is taken as stored, so a test can start from any list including an empty one.
  UseSmileIDSampleMemoryJobsRepository([
    List<UseSmileIDSampleJob> initial = const <UseSmileIDSampleJob>[],
  ]) : _jobs = List<UseSmileIDSampleJob>.of(initial);

  final List<UseSmileIDSampleJob> _jobs;

  @override
  Future<List<UseSmileIDSampleJob>?> read() async =>
      List<UseSmileIDSampleJob>.unmodifiable(_jobs);

  List<UseSmileIDSampleJob> _lastRemoved = const <UseSmileIDSampleJob>[];

  @override
  Future<void> seedFixtures(int nowMillis) async {
    final Set<String> stored = _jobs
        .map((UseSmileIDSampleJob job) => job.id)
        .toSet();
    _jobs.addAll(
      useSmileIDSampleJobFixtures(
        nowMillis,
      ).where((UseSmileIDSampleJob job) => !stored.contains(job.id)),
    );
  }

  @override
  Future<int> remove(Set<String> ids) async {
    final List<UseSmileIDSampleJob> taken = _jobs
        .where((UseSmileIDSampleJob job) => ids.contains(job.id))
        .toList();
    if (taken.isEmpty) {
      return 0;
    }
    _lastRemoved = taken;
    _jobs.removeWhere((UseSmileIDSampleJob job) => ids.contains(job.id));
    return taken.length;
  }

  @override
  Future<void> undoRemove() async {
    _jobs.addAll(_lastRemoved);
    _lastRemoved = const <UseSmileIDSampleJob>[];
  }
}

/// The design's eleven, which only `seedJobs` reaches.
List<UseSmileIDSampleJob> useSmileIDSampleJobFixtures(
  int nowMillis,
) => <UseSmileIDSampleJob>[
  for (int i = 0; i < _fixtureStatuses.length; i++)
    UseSmileIDSampleJob(
      id: 'job_${_two(i)}ky31za${_two(i * 7 % 100)}',
      userId: 'user_${_two(i)}ky31za${_two(i * 3 % 100)}',
      product: UseSmileIDSampleProduct
          .values[i % UseSmileIDSampleProduct.values.length],
      status: _fixtureStatuses[i],
      createdAtMillis: nowMillis - i * _fixtureSpacingMillis,
      message: _fixtureMessages[_fixtureStatuses[i]]!,
      // The HTTP outcome, which is not the verdict: a still-processing job was accepted, not
      // completed, and the detail page colours this by the transport rather than the result.
      httpStatus: _fixtureStatuses[i] == UseSmileIDSampleStatus.processing
          ? 202
          : 200,
    ),
];

/// The order the design draws, which is what makes the chip counts 11 / 6 / 2 / 2.
const List<UseSmileIDSampleStatus> _fixtureStatuses = <UseSmileIDSampleStatus>[
  UseSmileIDSampleStatus.clear,
  UseSmileIDSampleStatus.processing,
  UseSmileIDSampleStatus.clear,
  UseSmileIDSampleStatus.attention,
  UseSmileIDSampleStatus.blocked,
  UseSmileIDSampleStatus.clear,
  UseSmileIDSampleStatus.clear,
  UseSmileIDSampleStatus.attention,
  UseSmileIDSampleStatus.blocked,
  UseSmileIDSampleStatus.clear,
  UseSmileIDSampleStatus.clear,
];

/// What the server would have said, one line per verdict.
const Map<UseSmileIDSampleStatus, String> _fixtureMessages =
    <UseSmileIDSampleStatus, String>{
      UseSmileIDSampleStatus.clear: 'Approved',
      UseSmileIDSampleStatus.attention: 'Provisional — needs review',
      UseSmileIDSampleStatus.blocked: 'Rejected',
      UseSmileIDSampleStatus.processing: 'Submitted, awaiting result',
    };

/// Five hours, which is what spreads the eleven across three days.
const int _fixtureSpacingMillis = 5 * 60 * 60 * 1000;

/// Two digits, so the ids sort and elide the same way every run.
String _two(int value) => value.toString().padLeft(2, '0');
