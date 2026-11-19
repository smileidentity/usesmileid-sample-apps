import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

/// spec/error-handling.json: the message and the one action every failure resolves to.
void main() {
  final Map<String, Object?> file = spec('error-handling.json');
  final Map<String, Object?> actions = file['actions']! as Map<String, Object?>;
  final List<Map<String, Object?>> submission = objects(file['submission']);
  final List<Map<String, Object?>> result = objects(file['result']);
  final Map<String, Object?> fallback =
      file['fallback']! as Map<String, Object?>;
  final Map<String, Object?> unsubmitted =
      file['unsubmitted']! as Map<String, Object?>;
  final Map<String, Object?> strings = spec('l10n/app/en.json');

  List<T> list<T>(Object? value) =>
      (value as List<Object?>? ?? const <Object?>[]).cast<T>();

  // A resolution as the spec states one, with the action's limit where the row has none.
  String expected(Map<String, Object?> row) {
    final Map<String, Object?> action =
        actions[row['action']]! as Map<String, Object?>;
    return <Object?>[
      row['id'],
      row['message'],
      row['action'],
      list<int>(row['backoffSeconds']),
      row['maxUses'] ?? action['maxUses'],
      row['waitsFor'],
    ].join('|');
  }

  String stated(UseSmileIDSampleErrorResolution resolution) => <Object?>[
    resolution.id,
    resolution.message.key,
    resolution.action.name,
    resolution.backoffSeconds,
    resolution.maxUses,
    resolution.waitsForConnection ? 'connection' : null,
  ].join('|');

  String row(Object? id) => expected(
    <Map<String, Object?>>[
      ...submission,
      ...result,
    ].firstWhere((Map<String, Object?> row) => row['id'] == id),
  );

  test('the table holds the spec\'s rows in order', () {
    expect(
      UseSmileIDSampleErrorHandling.submission.map(
        (UseSmileIDSampleErrorResolution row) => row.id,
      ),
      submission.map((Map<String, Object?> row) => row['id']),
    );
    expect(
      UseSmileIDSampleErrorHandling.result.map(
        (UseSmileIDSampleErrorResolution row) => row.id,
      ),
      result.map((Map<String, Object?> row) => row['id']),
    );
  });

  test('every row resolves to its message, action and limits', () {
    for (final Map<String, Object?> row in submission) {
      final String? text = list<String>(
        row['serverMessageContains'],
      ).firstOrNull;
      for (final int status in list<int>(row['status'])) {
        expect(
          stated(
            UseSmileIDSampleErrorHandling.forStatus(
              status,
              serverMessage: text,
            ),
          ),
          expected(row),
          reason: '$status "$text"',
        );
      }
      final Object? transport = row['transport'];
      if (transport != null) {
        expect(
          stated(
            UseSmileIDSampleErrorHandling.forTransport(
              UseSmileIDSampleTransportFailure.values.byName(
                transport as String,
              ),
            ),
          ),
          expected(row),
          reason: transport,
        );
      }
    }
    for (final Map<String, Object?> row in result) {
      final String? text = list<String>(
        row['serverMessageContains'],
      ).firstOrNull;
      for (final String reason in list<String>(row['reasons'])) {
        expect(
          stated(
            UseSmileIDSampleErrorHandling.forReason(
              reason,
              serverMessage: text,
            ),
          ),
          expected(row),
          reason: '$reason "$text"',
        );
      }
    }
  });

  test('every case resolves as the spec says', () {
    final List<Map<String, Object?>> cases = objects(file['cases']);
    expect(cases, isNotEmpty);
    for (final Map<String, Object?> c in cases) {
      final String? text = c['serverMessage'] as String?;
      final UseSmileIDSampleErrorResolution resolved = switch (c) {
        {'status': final int status} => UseSmileIDSampleErrorHandling.forStatus(
          status,
          serverMessage: text,
        ),
        {'transport': final String transport} =>
          UseSmileIDSampleErrorHandling.forTransport(
            UseSmileIDSampleTransportFailure.values.byName(transport),
          ),
        _ => UseSmileIDSampleErrorHandling.forReason(
          c['reason'] as String?,
          serverMessage: text,
        ),
      };
      expect(resolved.id, c['resolves'], reason: '$c');
    }
  });

  test('a failure the table does not name resolves as the fallback', () {
    expect(
      stated(UseSmileIDSampleErrorHandling.forStatus(599)),
      row(fallback['submission']),
    );
    expect(
      stated(UseSmileIDSampleErrorHandling.forReason('not_in_the_table')),
      row(fallback['result']),
    );
    expect(
      stated(UseSmileIDSampleErrorHandling.forReason(null)),
      row(fallback['result']),
    );
  });

  test(
    'a run that ended before submission resolves as the unsubmitted row',
    () {
      expect(
        stated(UseSmileIDSampleErrorHandling.unsubmitted),
        expected(unsubmitted),
      );
    },
  );

  test('every fraud and compliance outcome shows the one message', () {
    final List<String> reasons = list<String>(
      result.firstWhere(
        (Map<String, Object?> row) => row['id'] == 'notVerified',
      )['reasons'],
    );
    expect(reasons.length, greaterThan(1));
    for (final String reason in reasons) {
      final UseSmileIDSampleErrorResolution resolved =
          UseSmileIDSampleErrorHandling.forReason(
            reason,
            serverMessage: 'Verification failed: $reason',
          );
      expect(
        resolved.message,
        UseSmileIDSampleErrorMessage.notVerified,
        reason: reason,
      );
      expect(resolved.action, UseSmileIDSampleErrorAction.exit, reason: reason);
    }
    expect(
      UseSmileIDSampleStrings.forLanguage('en').errorNotVerified,
      "We couldn't verify your identity.",
    );
  });

  test('the actions are the spec\'s, with its buttons and limits', () {
    expect(
      UseSmileIDSampleErrorAction.values.map(
        (UseSmileIDSampleErrorAction action) => action.name,
      ),
      actions.keys,
    );
    for (final UseSmileIDSampleErrorAction action
        in UseSmileIDSampleErrorAction.values) {
      final Map<String, Object?> stated =
          actions[action.name]! as Map<String, Object?>;
      expect(action.buttonKey, stated['button'], reason: action.name);
      expect(action.maxUses, stated['maxUses'], reason: action.name);
    }
  });

  test('every message and button has a string', () {
    final Set<Object?> used = <Map<String, Object?>>[
      ...submission,
      ...result,
      unsubmitted,
    ].map((Map<String, Object?> row) => row['message']).toSet();
    expect(
      UseSmileIDSampleErrorMessage.values
          .map((UseSmileIDSampleErrorMessage message) => message.key)
          .toSet(),
      used,
    );
    for (final Object? key in <Object?>{
      ...used,
      ...UseSmileIDSampleErrorAction.values.map(
        (UseSmileIDSampleErrorAction action) => action.buttonKey,
      ),
    }) {
      expect(strings[key], isA<String>(), reason: '$key');
      expect(strings[key]! as String, isNotEmpty, reason: '$key');
    }
  });
}
