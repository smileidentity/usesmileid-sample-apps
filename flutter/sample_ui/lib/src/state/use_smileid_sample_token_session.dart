import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_environment.dart';
import 'use_smileid_sample_token_decoder.dart';

/// A linked session, held as an absolute deadline; built by the decoder, so it cannot exist without a token that decodes.
@immutable
class UseSmileIDSampleTokenSession {
  /// Public so a test can build one; the app only ever gets one from [UseSmileIDSampleTokenDecoder].
  const UseSmileIDSampleTokenSession({
    required this.id,
    required this.token,
    required this.issuedAtMillis,
    required this.expiresAtMillis,
    required this.bindings,
    required this.environment,
    this.partnerId,
  });

  /// A display handle: the token's `jti`, else a digest of it. Never a prefix of the credential.
  final String id;

  /// The bearer credential a run submits under; never logged, rendered or tagged.
  final String token;

  /// The token's `iat`, in epoch milliseconds.
  final int issuedAtMillis;

  /// The token's `exp`, in epoch milliseconds.
  final int expiresAtMillis;

  /// What the token binds.
  final UseSmileIDSampleTokenBindings bindings;

  /// The partner the token was minted for, which wins over the local profile; never logged.
  final String? partnerId;

  /// From the token's own `api_url` claim; the decoder refuses a token it cannot place.
  final UseSmileIDSampleEnvironment environment;

  /// What is left at [nowMillis], never negative.
  Duration remaining(int nowMillis) => Duration(
    milliseconds: expiresAtMillis - nowMillis < 0
        ? 0
        : expiresAtMillis - nowMillis,
  );

  /// True from the deadline on.
  bool hasExpired(int nowMillis) => nowMillis >= expiresAtMillis;

  /// 1 fresh to 0 expired over the token's own span, for the nav bar's ring; a zero span cannot divide to NaN.
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

  /// Redacted: a generated description is how a bearer credential reaches a log.
  @override
  String toString() =>
      'UseSmileIDSampleTokenSession(id: $id, environment: ${environment.label}, '
      'expiresAtMillis: $expiresAtMillis)';
}

/// `m:ss`, growing an hours part when the span needs one: an 8h token reads 7:59:12, not 479:12.
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
