import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_environment.dart';
import 'use_smileid_sample_token_decoder.dart';

/// A linked session, held as an absolute deadline.
@immutable
class UseSmileIDSampleTokenSession {
  /// Built by the decoder in the app; public for tests.
  const UseSmileIDSampleTokenSession({
    required this.id,
    required this.token,
    required this.issuedAtMillis,
    required this.expiresAtMillis,
    required this.bindings,
    required this.environment,
    this.partnerId,
  });

  /// A display handle: the `jti`, else a digest; never a prefix.
  final String id;

  /// The bearer credential; never logged, rendered or tagged.
  final String token;

  /// The token's `iat`, in epoch milliseconds.
  final int issuedAtMillis;

  /// The token's `exp`, in epoch milliseconds.
  final int expiresAtMillis;

  /// What the token binds.
  final UseSmileIDSampleTokenBindings bindings;

  /// The partner the token was minted for; never logged.
  final String? partnerId;

  /// The environment the token's `api_url` names.
  final UseSmileIDSampleEnvironment environment;

  /// What is left at [nowMillis], never negative.
  Duration remaining(int nowMillis) => Duration(
    milliseconds: expiresAtMillis - nowMillis < 0
        ? 0
        : expiresAtMillis - nowMillis,
  );

  /// True from the deadline on.
  bool hasExpired(int nowMillis) => nowMillis >= expiresAtMillis;

  /// 1 fresh to 0 expired, over the token's own span.
  double progress(int nowMillis) {
    final int span = expiresAtMillis - issuedAtMillis < 1
        ? 1
        : expiresAtMillis - issuedAtMillis;
    return (remaining(nowMillis).inMilliseconds / span).clamp(0, 1).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleTokenSession && other.token == token;

  @override
  int get hashCode => token.hashCode;

  /// Redacted, so the credential never reaches a log.
  @override
  String toString() =>
      'UseSmileIDSampleTokenSession(id: $id, environment: ${environment.label}, '
      'expiresAtMillis: $expiresAtMillis)';
}

/// `m:ss`, with an hours part when needed: 7:59:12, not 479:12.
String useSmileIDSampleCountdown(Duration remaining) {
  final int total = remaining.inSeconds;
  final int hours = total ~/ Duration.secondsPerHour;
  final int minutes =
      (total % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
  final String seconds = (total % Duration.secondsPerMinute).toString().padLeft(
    2,
    '0',
  );
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}
