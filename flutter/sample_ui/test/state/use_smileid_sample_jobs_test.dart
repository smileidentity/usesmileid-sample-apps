import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The job model, its grouping and the filter counts, which the screen only renders.
void main() {
  UseSmileIDSampleJob job(
    String id,
    UseSmileIDSampleStatus status,
    DateTime at,
  ) => UseSmileIDSampleJob(
    id: id,
    userId: 'user_$id',
    product: UseSmileIDSampleProduct.values.first,
    status: status,
    createdAtMillis: at.millisecondsSinceEpoch,
  );

  group('grouping', () {
    test('puts the newest day first and the newest job first within it', () {
      final List<UseSmileIDSampleJobDay>
      days = useSmileIDSampleGroupByDay(<UseSmileIDSampleJob>[
        job('older', UseSmileIDSampleStatus.clear, DateTime(2026, 7, 14, 9)),
        job('newest', UseSmileIDSampleStatus.clear, DateTime(2026, 7, 16, 18)),
        job('middle', UseSmileIDSampleStatus.clear, DateTime(2026, 7, 16, 8)),
      ]);

      expect(days, hasLength(2));
      expect(days.first.jobs.map((UseSmileIDSampleJob j) => j.id), <String>[
        'newest',
        'middle',
      ]);
      expect(days.last.jobs.single.id, 'older');
    });

    test('splits two jobs minutes apart across midnight into two days', () {
      final List<UseSmileIDSampleJobDay> days =
          useSmileIDSampleGroupByDay(<UseSmileIDSampleJob>[
            job(
              'before',
              UseSmileIDSampleStatus.clear,
              DateTime(2026, 7, 15, 23, 58),
            ),
            job(
              'after',
              UseSmileIDSampleStatus.clear,
              DateTime(2026, 7, 16, 0, 2),
            ),
          ]);

      expect(days, hasLength(2));
    });
  });

  group('the day header', () {
    final int now = DateTime(2026, 7, 16, 18, 30).millisecondsSinceEpoch;
    int startOf(DateTime at) =>
        useSmileIDSampleStartOfDayMillis(at.millisecondsSinceEpoch);

    test('names today and yesterday and nothing older', () {
      expect(
        useSmileIDSampleRelativeDay(startOf(DateTime(2026, 7, 16, 1)), now),
        'TODAY',
      );
      expect(
        useSmileIDSampleRelativeDay(startOf(DateTime(2026, 7, 15, 23)), now),
        'YESTERDAY',
      );
      expect(
        useSmileIDSampleRelativeDay(startOf(DateTime(2026, 7, 14, 23)), now),
        isEmpty,
      );
    });

    // Subtracting 86_400_000 lands inside the WRONG day either side of a clock change, which is
    // why yesterday is calendar arithmetic rather than a day of milliseconds.
    test('names yesterday across a 23-hour day', () {
      final int springForward = DateTime(
        2026,
        3,
        30,
        12,
      ).millisecondsSinceEpoch;
      // Only a zone that changes clock that night has a 23-hour day; UTC would pass the bug this forbids.
      expect(
        DateTime(2026, 3, 30).difference(DateTime(2026, 3, 29)).inHours,
        23,
        reason: 'run under TZ=Europe/London, as flutter/verify.sh does',
      );
      expect(
        useSmileIDSampleRelativeDay(
          startOf(DateTime(2026, 3, 29, 12)),
          springForward,
        ),
        'YESTERDAY',
      );
    });

    test('is cased and ordered as the design draws it', () {
      expect(
        useSmileIDSampleAbsoluteDay(startOf(DateTime(2026, 7, 16))),
        'THU, 16 JUL 2026',
      );
    });

    test('renders a time as a fixed-width clock', () {
      expect(
        useSmileIDSampleTimeLabel(
          DateTime(2026, 7, 16, 9, 2, 5).millisecondsSinceEpoch,
        ),
        '09:02:05',
      );
    });
  });

  group('ids', () {
    test('are elided at eight characters, with the ellipsis as one glyph', () {
      expect(
        job('0123456789', UseSmileIDSampleStatus.clear, DateTime(2026)).shortId,
        '01234567…',
      );
    });

    test('are left alone when they already fit', () {
      expect(
        job('12345678', UseSmileIDSampleStatus.clear, DateTime(2026)).shortId,
        '12345678',
      );
    });
  });

  group('filters', () {
    test('are the four the design draws, and Processing is not among them', () {
      expect(
        UseSmileIDSampleJobFilter.values.map(
          (UseSmileIDSampleJobFilter f) => f.label,
        ),
        <String>['All', 'Clear', 'Attention', 'Blocked'],
      );
      expect(
        UseSmileIDSampleJobFilter.values.map(
          (UseSmileIDSampleJobFilter f) => f.status,
        ),
        isNot(contains(UseSmileIDSampleStatus.processing)),
      );
    });

    // The count under a chip is what that chip would show, not what the ACTIVE one shows: a reader
    // switching filters has to see where the rows went.
    test('count against the whole list, not the visible one', () {
      final UseSmileIDSampleVerificationsState state =
          UseSmileIDSampleVerificationsState(
            jobs: useSmileIDSampleJobFixtures(
              DateTime(2026, 7, 16, 18).millisecondsSinceEpoch,
            ),
            nowMillis: DateTime(2026, 7, 16, 18).millisecondsSinceEpoch,
            filter: UseSmileIDSampleJobFilter.blocked,
          );

      expect(state.countFor(UseSmileIDSampleJobFilter.all), 11);
      expect(state.countFor(UseSmileIDSampleJobFilter.clear), 6);
      expect(state.countFor(UseSmileIDSampleJobFilter.attention), 2);
      expect(state.countFor(UseSmileIDSampleJobFilter.blocked), 2);
      expect(state.visible, hasLength(2));
    });
  });

  group('the fixtures', () {
    final List<UseSmileIDSampleJob> fixtures = useSmileIDSampleJobFixtures(
      DateTime(2026, 7, 16, 18).millisecondsSinceEpoch,
    );

    test('are the design eleven with unique ids', () {
      expect(fixtures, hasLength(11));
      expect(
        fixtures.map((UseSmileIDSampleJob j) => j.id).toSet(),
        hasLength(11),
      );
    });

    test(
      'carry the transport outcome, not the verdict, as their HTTP status',
      () {
        for (final UseSmileIDSampleJob each in fixtures) {
          expect(
            each.httpStatus,
            each.status == UseSmileIDSampleStatus.processing ? 202 : 200,
            reason: each.id,
          );
        }
      },
    );

    test('can never refresh, because a fixture ran under no session', () {
      expect(
        fixtures.every(
          (UseSmileIDSampleJob j) => j.sessionId == null && j.partnerId == null,
        ),
        isTrue,
      );
    });
  });

  group('the store', () {
    test('holds nothing until the fixtures are asked for', () async {
      final UseSmileIDSampleJobsRepository jobs =
          UseSmileIDSampleMemoryJobsRepository();
      expect(await jobs.read(), isEmpty);

      await jobs.seedFixtures(DateTime(2026, 7, 16).millisecondsSinceEpoch);
      expect(await jobs.read(), hasLength(11));
    });

    test('seeding twice adds nothing the second time', () async {
      final UseSmileIDSampleJobsRepository jobs =
          UseSmileIDSampleMemoryJobsRepository();
      final int now = DateTime(2026, 7, 16).millisecondsSinceEpoch;

      await jobs.seedFixtures(now);
      await jobs.seedFixtures(now);

      expect(await jobs.read(), hasLength(11));
    });
  });

  group('the detail page formats', () {
    UseSmileIDSampleJob at(DateTime when, {int? httpStatus}) =>
        UseSmileIDSampleJob(
          id: 'job_1',
          userId: 'user_1',
          product: UseSmileIDSampleProduct.values.first,
          status: UseSmileIDSampleStatus.clear,
          createdAtMillis: when.millisecondsSinceEpoch,
          httpStatus: httpStatus,
        );

    // UTC and not local, unlike the list's clock: a job id travels to support with its timestamp,
    // and a local one cannot be read against a server log without knowing the phone's zone.
    test('the instant in UTC, to the millisecond', () {
      expect(
        at(DateTime.utc(2026, 7, 16, 13, 3, 41, 7)).createdAtLabel,
        '2026-07-16T13:03:41.007Z',
      );
    });

    test('the same instant regardless of the phone zone', () {
      final DateTime local = DateTime(2026, 7, 16, 13, 3, 41);
      expect(at(local).createdAtLabel, at(local.toUtc()).createdAtLabel);
    });

    test('the transport outcome, named where the design names it', () {
      expect(at(DateTime(2026), httpStatus: 200).httpStatusLabel, '200 OK');
      expect(
        at(DateTime(2026), httpStatus: 202).httpStatusLabel,
        '202 Accepted',
      );
      expect(at(DateTime(2026), httpStatus: 403).httpStatusLabel, '403');
      expect(at(DateTime(2026)).httpStatusLabel, isEmpty);
    });

    // Null is neither success nor failure: a job that never reached the API has no transport
    // outcome, and colouring it red would accuse the server of refusing a request it never saw.
    test('success is unknown for a job that never reached the API', () {
      expect(at(DateTime(2026), httpStatus: 200).httpSucceeded, isTrue);
      expect(at(DateTime(2026), httpStatus: 202).httpSucceeded, isTrue);
      expect(at(DateTime(2026), httpStatus: 403).httpSucceeded, isFalse);
      expect(at(DateTime(2026), httpStatus: 500).httpSucceeded, isFalse);
      expect(at(DateTime(2026)).httpSucceeded, isNull);
    });

    // The reason is the outcome's now; the row owes only the fact the outcome reads.
    test('no fixture carries a session', () {
      expect(at(DateTime(2026)).sessionId, isNull);
      expect(
        useSmileIDSampleJobFixtures(
          DateTime(2026).millisecondsSinceEpoch,
        ).every((UseSmileIDSampleJob j) => j.sessionId == null),
        isTrue,
        reason: 'every fixture ran under no session',
      );
    });
  });

  // Null is NOT an empty list: the screen must draw neither empty state until the store answers.
  test('a state with no answer yet shows nothing and counts nothing', () {
    const UseSmileIDSampleVerificationsState state =
        UseSmileIDSampleVerificationsState(jobs: null, nowMillis: 0);

    expect(state.visible, isEmpty);
    expect(state.countFor(UseSmileIDSampleJobFilter.all), 0);
  });
}
