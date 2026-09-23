import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/status/use_smileid_sample_http_job_status_source.dart';

/// The status fetch under a server that never answers.
void main() {
  late ServerSocket silent;
  final List<Socket> held = <Socket>[];

  setUp(() async {
    silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    silent.listen(held.add);
  });

  tearDown(() async {
    for (final Socket socket in held) {
      socket.destroy();
    }
    held.clear();
    await silent.close();
  });

  test('a server that never answers ends in a timeout, not a hang', () async {
    final HttpClient client = HttpClient()
      ..findProxy = (Uri _) => 'PROXY 127.0.0.1:${silent.port}';
    final UseSmileIDSampleHttpJobStatusSource source =
        UseSmileIDSampleHttpJobStatusSource(
          client: client,
          timeout: const Duration(milliseconds: 200),
        );

    await expectLater(
      source
          .check(jobId: 'job_1', token: 'fixture', sandbox: true)
          .timeout(const Duration(seconds: 5)),
      throwsA(
        isA<TimeoutException>().having(
          (TimeoutException e) => e.duration,
          'the source\'s own budget, not the test\'s',
          const Duration(milliseconds: 200),
        ),
      ),
    );
  });

  test(
    'the store turns that timeout into a Failed outcome and can refresh again',
    () async {
      final HttpClient client = HttpClient()
        ..findProxy = (Uri _) => 'PROXY 127.0.0.1:${silent.port}';
      final UseSmileIDSampleHttpJobStatusSource source =
          UseSmileIDSampleHttpJobStatusSource(
            client: client,
            timeout: const Duration(milliseconds: 200),
          );
      final UseSmileIDSampleMemoryJobsRepository store =
          UseSmileIDSampleMemoryJobsRepository(<UseSmileIDSampleJob>[_row]);
      final UseSmileIDSampleRefreshSession session =
          UseSmileIDSampleRefreshSession(
            token: 'fixture',
            partnerId: 'partner-1',
            expiresAtMillis: DateTime.now().millisecondsSinceEpoch + 3600000,
          );

      Future<UseSmileIDSampleStatusRefresh?> refresh() => store
          .refresh(
            jobId: _row.id,
            session: session,
            nowMillis: DateTime.now().millisecondsSinceEpoch,
            source: source,
          )
          .timeout(const Duration(seconds: 5));

      expect(await refresh(), isA<UseSmileIDSampleStatusFailed>());
      // Null would mean the in-flight guard never released.
      expect(await refresh(), isA<UseSmileIDSampleStatusFailed>());
    },
  );
}

final UseSmileIDSampleJob _row = UseSmileIDSampleJob(
  id: 'job_1',
  userId: 'user_1',
  product: UseSmileIDSampleProduct.values.first,
  status: UseSmileIDSampleStatus.processing,
  createdAtMillis: 0,
  message: 'Submitted',
  httpStatus: 202,
  sessionId: 'session-1',
  partnerId: 'partner-1',
);
