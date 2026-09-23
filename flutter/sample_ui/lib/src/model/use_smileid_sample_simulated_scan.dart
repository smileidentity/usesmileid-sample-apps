import 'package:flutter/foundation.dart';

/// How long a simulated scan's token lasts: the Portal's own allow-list, plus [ended] to reach the expiry gate without waiting.
enum UseSmileIDSampleSimulatedSpan {
  /// Fifteen minutes.
  fifteenMinutes('15m', Duration(minutes: 15)),

  /// One hour.
  oneHour('1h', Duration(hours: 1)),

  /// Eight hours.
  eightHours('8h', Duration(hours: 8)),

  /// Minted wholly in the past.
  ended('Expired', Duration(minutes: 15), inPast: true);

  const UseSmileIDSampleSimulatedSpan(
    this.label,
    this.span, {
    this.inPast = false,
  });

  /// The chip's label.
  final String label;

  /// `exp - iat`.
  final Duration span;

  /// Whether the whole span lies in the past.
  final bool inPast;
}

/// What a simulated scan's token binds; both off by default, so a simulated session never silently changes the screen set.
@immutable
class UseSmileIDSampleSimulatedBindings {
  /// Nothing bound.
  const UseSmileIDSampleSimulatedBindings({
    this.consent = false,
    this.userDetails = false,
  });

  /// A complete consent record, which removes the SDK's consent screen.
  final bool consent;

  /// Every user detail plus the ID parameters, which removes both host forms.
  final bool userDetails;

  /// Whether a `payload` claim is minted at all.
  bool get binds => consent || userDetails;

  /// A copy with either half replaced.
  UseSmileIDSampleSimulatedBindings copyWith({
    bool? consent,
    bool? userDetails,
  }) => UseSmileIDSampleSimulatedBindings(
    consent: consent ?? this.consent,
    userDetails: userDetails ?? this.userDetails,
  );

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleSimulatedBindings &&
      other.consent == consent &&
      other.userDetails == userDetails;

  @override
  int get hashCode => Object.hash(consent, userDetails);
}

/// What the scanner is doing, said out loud: found before linked, and a rejection that names itself and can be retried.
sealed class UseSmileIDSampleScanState {
  const UseSmileIDSampleScanState();
}

/// Camera live, nothing in hand.
class UseSmileIDSampleScanSearching extends UseSmileIDSampleScanState {
  /// No fields.
  const UseSmileIDSampleScanSearching();
}

/// A code is in hand and being decoded.
class UseSmileIDSampleScanFound extends UseSmileIDSampleScanState {
  /// No fields.
  const UseSmileIDSampleScanFound();
}

/// Decoded, and held on screen long enough to be read before the screen leaves.
class UseSmileIDSampleScanLinked extends UseSmileIDSampleScanState {
  /// [handle] and [remaining] only; never the token.
  const UseSmileIDSampleScanLinked({
    required this.handle,
    required this.remaining,
  });

  /// The session's display handle.
  final String handle;

  /// Its countdown, formatted.
  final String remaining;
}

/// Decoded into something that is not a session; the reason names a claim, never a value.
class UseSmileIDSampleScanRejected extends UseSmileIDSampleScanState {
  /// [reason] is the decoder's.
  const UseSmileIDSampleScanRejected(this.reason);

  /// Why the code is not a token.
  final String reason;
}
