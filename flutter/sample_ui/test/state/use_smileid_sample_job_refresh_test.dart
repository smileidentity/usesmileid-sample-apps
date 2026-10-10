import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The refresh sequence the four apps share, case for case with Expo's own suite.
void main() {
  const int now = 1750000000000;

  UseSmileIDSampleJob row({
    String id = 'job_1',
    bool sandbox = true,
    String? sessionId = 'sess_1',
    String? partnerId = 'partner_1',
    int createdAtMillis = now,
  }) => UseSmileIDSampleJob(
    id: id,
    userId: 'user_1',
    product: UseSmileIDSampleProduct.values.first,
    status: UseSmileIDSampleStatus.processing,
    createdAtMillis: createdAtMillis,
    message: 'Submitted, awaiting result',
    httpStatus: 202,
    sandbox: sandbox,
    sessionId: sessionId,
    partnerId: partnerId,
  );

  UseSmileIDSampleRefreshSession session({
    String? partnerId = 'partner_1',
    int? expiresAtMillis,
  }) => UseSmileIDSampleRefreshSession(
    token: 'token-1',
    partnerId: partnerId,
    expiresAtMillis: expiresAtMillis ?? now + 1,
  );

  const UseSmileIDSampleStatusUpdated updated = UseSmileIDSampleStatusUpdated(
    status: UseSmileIDSampleStatus.clear,
    message: 'Approved',
    httpCode: 200,
  );

  late UseSmileIDSampleMemoryJobsRepository store;

  setUp(() => store = UseSmileIDSampleMemoryJobsRepository());

  group('a 404', () {
    test(
      'reads as processing while the job is new, and as a failure after the window',
      () async {
        await store.add(row(id: 'job_new', createdAtMillis: now - 60000));
        await store.add(
          row(
            id: 'job_old',
            createdAtMillis: now - useSmileIDSampleNotRecordedWindowMillis,
          ),
        );
        final _Returning source = _Returning(
          const UseSmileIDSampleStatusNotRecorded(),
        );

        expect(
          await store.refresh(
            jobId: 'job_new',
            session: session(),
            nowMillis: now,
            source: source,
          ),
          isA<UseSmileIDSampleStatusStillProcessing>(),
        );
        final UseSmileIDSampleStatusRefresh? old = await store.refresh(
          jobId: 'job_old',
          session: session(),
          nowMillis: now,
          source: source,
        );
        expect((old! as UseSmileIDSampleStatusFailed).reason, 'HTTP 404');
      },
    );
  });

  test(
    'the list backs off from 5 seconds to a minute and stops after twelve checks',
    () {
      expect(
        <Duration?>[
          for (int i = 0; i <= 12; i++) useSmileIDSampleProcessingPollDelay(i),
        ],
        <Duration?>[
          for (final int s in <int>[
            5,
            10,
            20,
            40,
            60,
            60,
            60,
            60,
            60,
            60,
            60,
            60,
          ])
            Duration(seconds: s),
          null,
        ],
      );
    },
  );

  group('the list\'s check', () {
    test(
      'asks about every processing row and counts those still processing',
      () async {
        await store.add(row(id: 'job_done'));
        await store.add(row(id: 'job_waiting'));
        final _ById source = _ById(<String, UseSmileIDSampleStatusRefresh>{
          'job_done': updated,
          'job_waiting': const UseSmileIDSampleStatusStillProcessing(),
        });

        final int pending = await store.refreshProcessing(
          session: session(),
          nowMillis: now,
          source: source,
        );

        expect(pending, 1);
        expect(source.asked, <String>{'job_done', 'job_waiting'});
        expect(
          (await store.find('job_done'))?.status,
          UseSmileIDSampleStatus.clear,
        );
      },
    );

    test(
      'does not count rows the session cannot ask about, so the list stops',
      () async {
        await store.add(row(id: 'job_fixture', sessionId: null));
        await store.add(row(id: 'job_other', partnerId: 'partner_2'));
        final _ById source = _ById(
          const <String, UseSmileIDSampleStatusRefresh>{},
        );

        expect(
          await store.refreshProcessing(
            session: session(),
            nowMillis: now,
            source: source,
          ),
          0,
        );
        expect(
          await store.refreshProcessing(
            session: null,
            nowMillis: now,
            source: source,
          ),
          0,
        );
        expect(source.asked, isEmpty);
      },
    );
  });

  group('refresh', () {
    test('reads the row, asks the source and writes back', () async {
      await store.add(row());

      final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
        jobId: 'job_1',
        session: session(),
        nowMillis: now,
        source: _Returning(updated),
      );

      expect(outcome, same(updated));
      final UseSmileIDSampleJob? after = await store.find('job_1');
      expect(after?.status, UseSmileIDSampleStatus.clear);
      expect(after?.message, 'Approved');
      expect(after?.httpStatus, 200);
    });

    test('takes the environment from the row, never from a toggle', () async {
      await store.add(row(sandbox: false));
      final _Recording source = _Recording(updated);

      await store.refresh(
        jobId: 'job_1',
        session: session(),
        nowMillis: now,
        source: source,
      );

      expect(source.sandbox, isFalse);
    });

    test(
      'matches on the partner, so a newer session for the same partner still refreshes',
      () async {
        await store.add(row(sessionId: 'sess_OLD'));

        final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
          jobId: 'job_1',
          session: session(),
          nowMillis: now,
          source: _Returning(updated),
        );

        expect(outcome, same(updated));
      },
    );

    test(
      'reports a partner mismatch rather than sending another account the credential',
      () async {
        await store.add(row());
        final _Recording source = _Recording(updated);

        final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
          jobId: 'job_1',
          session: session(partnerId: 'partner_2'),
          nowMillis: now,
          source: source,
        );

        expect(outcome, isA<UseSmileIDSampleStatusPartnerMismatch>());
        expect(source.asked, isFalse);
      },
    );

    test(
      'says a fixture row was never submitted, before any partner check',
      () async {
        await store.add(row(sessionId: null, partnerId: null));
        final _Recording source = _Recording(updated);

        final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
          jobId: 'job_1',
          session: session(),
          nowMillis: now,
          source: source,
        );

        expect(outcome, isA<UseSmileIDSampleStatusNoServerJob>());
        expect(source.asked, isFalse);
      },
    );

    test('says there is no session when none is live', () async {
      await store.add(row());
      final _Recording source = _Recording(updated);

      final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
        jobId: 'job_1',
        session: null,
        nowMillis: now,
        source: source,
      );

      expect(outcome, isA<UseSmileIDSampleStatusNoSession>());
      expect(source.asked, isFalse);
    });

    test('says there is no session when the live one has expired', () async {
      await store.add(row());
      final _Recording source = _Recording(updated);

      final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
        jobId: 'job_1',
        session: session(expiresAtMillis: now),
        nowMillis: now,
        source: source,
      );

      expect(outcome, isA<UseSmileIDSampleStatusNoSession>());
      expect(source.asked, isFalse);
    });

    test('reports a missing row rather than throwing', () async {
      final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
        jobId: 'nope',
        session: session(),
        nowMillis: now,
        source: _Returning(updated),
      );

      expect(
        (outcome! as UseSmileIDSampleStatusFailed).message(_en),
        'The verification is no longer stored',
      );
    });

    // A delete landing mid-refresh wins; the write that follows must not bring the row back.
    test(
      'a row deleted while the source was answering is not resurrected',
      () async {
        await store.add(row());

        final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
          jobId: 'job_1',
          session: session(),
          nowMillis: now,
          source: _RemovingBeforeAnswering(store, updated),
        );

        expect(
          (outcome! as UseSmileIDSampleStatusFailed).message(_en),
          'The verification is no longer stored',
        );
        expect(await store.find('job_1'), isNull);
      },
    );

    test('reports a transport failure by type, never by message', () async {
      await store.add(row());

      final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
        jobId: 'job_1',
        session: session(),
        nowMillis: now,
        // A client error carries the request URL, and this text goes on screen.
        source: _Throwing(
          StateError('GET https://api.example/v3/status?token=SECRET failed'),
        ),
      );

      final String reason = (outcome! as UseSmileIDSampleStatusFailed).message(
        _en,
      );
      expect(reason, contains('StateError'));
      expect(reason, isNot(contains('SECRET')));
    });

    test(
      'passes a non-updated outcome straight through without writing',
      () async {
        await store.add(row());

        final UseSmileIDSampleStatusRefresh? outcome = await store.refresh(
          jobId: 'job_1',
          session: session(),
          nowMillis: now,
          source: _Returning(const UseSmileIDSampleStatusStillProcessing()),
        );

        expect(outcome, isA<UseSmileIDSampleStatusStillProcessing>());
        expect(
          (await store.find('job_1'))?.status,
          UseSmileIDSampleStatus.processing,
        );
      },
    );

    test('skips a second request for a row already in flight', () async {
      await store.add(row());
      final _Gated source = _Gated(updated);

      final Future<UseSmileIDSampleStatusRefresh?> first = store.refresh(
        jobId: 'job_1',
        session: session(),
        nowMillis: now,
        source: source,
      );
      final UseSmileIDSampleStatusRefresh? second = await store.refresh(
        jobId: 'job_1',
        session: session(),
        nowMillis: now,
        source: source,
      );

      expect(second, isNull);
      source.release();
      await first;
      expect(source.started, 1);
    });

    // Unrefreshable for the rest of the process is the failure a released guard prevents.
    test('releases the in-flight guard even when the source throws', () async {
      await store.add(row());
      await store.refresh(
        jobId: 'job_1',
        session: session(),
        nowMillis: now,
        source: _Throwing(StateError('boom')),
      );

      final UseSmileIDSampleStatusRefresh? second = await store.refresh(
        jobId: 'job_1',
        session: session(),
        nowMillis: now,
        source: _Returning(updated),
      );

      expect(second, same(updated));
    });
  });

  group('the outcome labels', () {
    final Map<UseSmileIDSampleStatusRefresh, String> expected =
        <UseSmileIDSampleStatusRefresh, String>{
          updated: 'Clear — Approved',
          UseSmileIDSampleStatusStillProcessing(): 'Still processing',
          UseSmileIDSampleStatusNoSession(): 'Scan a token first',
          UseSmileIDSampleStatusNoServerJob():
              'Not submitted under a scanned token',
          UseSmileIDSampleStatusPartnerMismatch():
              'Submitted by a different partner',
          UseSmileIDSampleStatusFailed('HTTP 401'):
              'Could not check status: HTTP 401',
        };

    test('say what Android says', () {
      expected.forEach((UseSmileIDSampleStatusRefresh outcome, String label) {
        expect(useSmileIDSampleRefreshLabel(outcome, _en), label);
      });
    });
  });
}

/// A source that answers with one outcome and records nothing else.
class _Returning implements UseSmileIDSampleJobStatusSource {
  _Returning(this.outcome);

  final UseSmileIDSampleStatusRefresh outcome;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async => outcome;
}

/// A source that remembers whether it was asked at all, and with which environment.
class _Recording implements UseSmileIDSampleJobStatusSource {
  _Recording(this.outcome);

  final UseSmileIDSampleStatusRefresh outcome;

  /// Whether the sequence reached the network at all.
  bool asked = false;

  /// The environment it was asked with.
  bool? sandbox;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async {
    asked = true;
    this.sandbox = sandbox;
    return outcome;
  }
}

/// A source that throws, so the sequence's own reporting is what the test reads.
class _Throwing implements UseSmileIDSampleJobStatusSource {
  _Throwing(this.error);

  final Object error;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async => throw error;
}

/// A source that deletes the row before answering, which is the race the write has to lose.
class _RemovingBeforeAnswering implements UseSmileIDSampleJobStatusSource {
  _RemovingBeforeAnswering(this.store, this.outcome);

  final UseSmileIDSampleJobsRepository store;

  final UseSmileIDSampleStatusRefresh outcome;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async {
    await store.remove(<String>{jobId});
    return outcome;
  }
}

/// A source held open until released, so a second refresh meets the first still running.
class _Gated implements UseSmileIDSampleJobStatusSource {
  _Gated(this.outcome);

  final UseSmileIDSampleStatusRefresh outcome;

  final Completer<void> _gate = Completer<void>();

  /// How many times the source was entered, which is what proves the second was skipped.
  int started = 0;

  /// Lets the held request finish.
  void release() => _gate.complete();

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async {
    started += 1;
    await _gate.future;
    return outcome;
  }
}

final UseSmileIDSampleStrings _en = UseSmileIDSampleStrings.forLanguage('en');

/// A source answering per job, and remembering which it was asked about.
class _ById implements UseSmileIDSampleJobStatusSource {
  _ById(this.answers);

  final Map<String, UseSmileIDSampleStatusRefresh> answers;

  /// The jobs it was asked about.
  final Set<String> asked = <String>{};

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async {
    asked.add(jobId);
    return answers[jobId] ?? const UseSmileIDSampleStatusStillProcessing();
  }
}
