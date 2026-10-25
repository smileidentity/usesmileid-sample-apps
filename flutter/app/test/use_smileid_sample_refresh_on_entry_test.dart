import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_session_providers.dart';
import 'support/use_smileid_sample_test_njia.dart';

/// Refreshing a processing row when its page opens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<void> open(
    WidgetTester tester,
    UseSmileIDSampleJobStatusSource source,
  ) async {
    final UseSmileIDSampleSessionRecord live = UseSmileIDSampleSessionRecord(
      live: _session,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...useSmileIDSampleTestNjia(),
          useSmileIDSampleJobsRepositoryProvider.overrideWithValue(
            UseSmileIDSampleMemoryJobsRepository(<UseSmileIDSampleJob>[_row]),
          ),
          useSmileIDSampleSessionRepositoryProvider.overrideWithValue(
            UseSmileIDSampleMemorySessionRepository(live),
          ),
          useSmileIDSampleStoredSessionProvider.overrideWithValue(live),
          useSmileIDSampleJobStatusSourceProvider.overrideWithValue(source),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          routerConfig: useSmileIDSampleTestRouter(
            UseSmileIDSampleRoutes.verificationDetails(_row.id),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  testWidgets(
    'a verdict lands and is announced as the status and the server message',
    (WidgetTester tester) async {
      await open(tester, const _Answering(_completed));

      expect(find.text('Clear — Job completed'), findsOne);
    },
  );

  testWidgets('a row still processing is asked again until its verdict lands', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      _Queued(<UseSmileIDSampleStatusRefresh>[
        const UseSmileIDSampleStatusStillProcessing(),
        _completed,
      ]),
    );
    expect(find.text('Clear — Job completed'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Clear — Job completed'), findsOne);
  });

  testWidgets('still processing on the way in says nothing', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      const _Answering(UseSmileIDSampleStatusStillProcessing()),
    );

    expect(find.text('Still processing'), findsNothing);
    expect(find.byType(UseSmileIDSampleToast), findsNothing);
    // Leaves, then lets the next check come due, which finds the page gone and stops.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}

const UseSmileIDSampleStatusUpdated _completed = UseSmileIDSampleStatusUpdated(
  status: UseSmileIDSampleStatus.clear,
  message: 'Job completed',
  httpCode: 200,
);

/// Answers in order, one answer per check.
class _Queued implements UseSmileIDSampleJobStatusSource {
  _Queued(this.answers);

  final List<UseSmileIDSampleStatusRefresh> answers;

  int _next = 0;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async => answers[_next++];
}

class _Answering implements UseSmileIDSampleJobStatusSource {
  const _Answering(this.answer);

  final UseSmileIDSampleStatusRefresh answer;

  @override
  Future<UseSmileIDSampleStatusRefresh> check({
    required String jobId,
    required String token,
    required bool sandbox,
  }) async => answer;
}

/// A live fixture session minted for the row's partner.
final UseSmileIDSampleTokenSession
_session = UseSmileIDSampleTokenDecoder.session(
  <String>[
        '{"alg":"none","typ":"JWT"}',
        '{"iat":${_nowSeconds - 60},"exp":${_nowSeconds + 3600},'
            '"api_url":"https://testapi.smileidentity.com/v3","partner_id":"partner-1"}',
        'sample-signature',
      ]
      .map((String it) => base64Url.encode(utf8.encode(it)).replaceAll('=', ''))
      .join('.'),
)!;

final UseSmileIDSampleJob _row = UseSmileIDSampleJob(
  id: 'job_00ky31za77',
  userId: 'user_00ky31za77',
  product: UseSmileIDSampleProduct.values.first,
  status: UseSmileIDSampleStatus.processing,
  createdAtMillis: DateTime.utc(2026, 7, 16, 14).millisecondsSinceEpoch,
  message: 'Submitted, awaiting result',
  httpStatus: 202,
  sessionId: 'session-1',
  partnerId: 'partner-1',
);

final int _nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
