import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_tokens.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_session_providers.dart';

/// The session notifier's writes: a retirement must never land over a newer link.
void main() {
  test(
    'a link made while a cold-start retirement is pending keeps the fresh session',
    () async {
      final UseSmileIDSampleTokenSession stale = _mint(
        UseSmileIDSampleSimulatedSpan.ended,
      );
      final UseSmileIDSampleTokenSession fresh = _mint(
        UseSmileIDSampleSimulatedSpan.fifteenMinutes,
      );
      final UseSmileIDSampleSessionRecord stored =
          UseSmileIDSampleSessionRecord(live: stale);
      final _SlowRepository repository = _SlowRepository(stored);
      final ProviderContainer container = ProviderContainer(
        overrides: [
          useSmileIDSampleSessionRepositoryProvider.overrideWithValue(
            repository,
          ),
          useSmileIDSampleStoredSessionProvider.overrideWithValue(stored),
        ],
      );
      addTearDown(container.dispose);

      // The first read is Simulate's link, which is what a cold start straight to the scanner does.
      await container
          .read(useSmileIDSampleSessionProvider.notifier)
          .link(fresh);
      await Future<void>.delayed(_settle);

      expect(container.read(useSmileIDSampleSessionProvider).live, fresh);
      expect(container.read(useSmileIDSampleSessionProvider).ended, isNull);
      expect((await repository.read()).live, fresh);
    },
  );

  test('a stale session still retires when nothing links over it', () async {
    final UseSmileIDSampleTokenSession stale = _mint(
      UseSmileIDSampleSimulatedSpan.ended,
    );
    final UseSmileIDSampleSessionRecord stored = UseSmileIDSampleSessionRecord(
      live: stale,
    );
    final _SlowRepository repository = _SlowRepository(stored);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        useSmileIDSampleSessionRepositoryProvider.overrideWithValue(repository),
        useSmileIDSampleStoredSessionProvider.overrideWithValue(stored),
      ],
    );
    addTearDown(container.dispose);

    container.read(useSmileIDSampleSessionProvider);
    await Future<void>.delayed(_settle);

    expect(container.read(useSmileIDSampleSessionProvider).live, isNull);
    expect(container.read(useSmileIDSampleSessionProvider).ended?.id, stale.id);
    expect((await repository.read()).ended?.id, stale.id);
  });
}

/// Every write takes a while, as a Keystore or Keychain write does, so writes can overlap.
class _SlowRepository extends UseSmileIDSampleRecordSessionRepository {
  _SlowRepository(UseSmileIDSampleSessionRecord initial)
    : _record = initial.encode();

  String? _record;

  @override
  Future<String?> readRecord() async => _record;

  @override
  Future<void> writeRecord(String? record) async {
    await Future<void>.delayed(_write);
    _record = record;
  }
}

UseSmileIDSampleTokenSession _mint(UseSmileIDSampleSimulatedSpan span) =>
    UseSmileIDSampleTokenDecoder.session(
      UseSmileIDSampleFlowTokens.session(
        span: span,
        bindings: const UseSmileIDSampleSimulatedBindings(),
        environment: UseSmileIDSampleEnvironment.sandbox,
        nowMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    )!;

const Duration _write = Duration(milliseconds: 40);
const Duration _settle = Duration(milliseconds: 300);
