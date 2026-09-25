import '../state/use_smileid_sample_profiles.dart';

/// Where the profiles are kept, read synchronously so the first frame already knows who is active.
abstract interface class UseSmileIDSampleProfilesRepository {
  /// The stored profiles; none on a first launch, or when what is stored cannot be read.
  UseSmileIDSampleProfiles read();

  /// Replaces the whole record in one write, so the list and the active id never disagree.
  Future<void> write(UseSmileIDSampleProfiles profiles);
}

/// The key the record is stored under, the same on all four apps.
const String useSmileIDSampleProfilesKey = 'sample_profiles';

/// The record held for one process, for tests and for a host that wants no persistence.
class UseSmileIDSampleMemoryProfilesRepository
    implements UseSmileIDSampleProfilesRepository {
  String? _stored;

  @override
  UseSmileIDSampleProfiles read() =>
      UseSmileIDSampleProfilesCodec.decode(_stored);

  @override
  Future<void> write(UseSmileIDSampleProfiles profiles) async =>
      _stored = UseSmileIDSampleProfilesCodec.encode(profiles);
}
