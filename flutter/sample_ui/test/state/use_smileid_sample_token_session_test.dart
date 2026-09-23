import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

/// The countdown and the ring over the Portal's three spans, cheaper than watching a device for eight hours.
void main() {
  test("the ring measures the token's own span, not a fixed five minutes", () {
    for (final Duration span in _spans) {
      final UseSmileIDSampleTokenSession session = _session(span);
      expect(session.progress(_now), closeTo(1, _tolerance), reason: '$span');
      expect(
        session.progress(_now + span.inMilliseconds ~/ 2),
        closeTo(0.5, _tolerance),
        reason: '$span',
      );
      expect(
        session.progress(_now + span.inMilliseconds),
        closeTo(0, _tolerance),
        reason: '$span',
      );
    }
  });

  test('an hour in, an eight hour token still has most of its ring', () {
    expect(
      _session(const Duration(hours: 8)).progress(_now + _hour),
      closeTo(0.875, _tolerance),
    );
  });

  test('progress is clamped either side of the span', () {
    final UseSmileIDSampleTokenSession session = _session(
      const Duration(minutes: 15),
    );
    expect(session.progress(_now - _hour), 1);
    expect(session.progress(_now + _hour), 0);
  });

  test('a zero span cannot divide the ring to NaN', () {
    final UseSmileIDSampleTokenSession session = _session(Duration.zero);
    expect(session.progress(_now).isNaN, isFalse);
  });

  test('a fresh countdown reads m:ss under an hour and h:mm:ss above it', () {
    expect(_countdown(const Duration(minutes: 15)), '15:00');
    expect(_countdown(const Duration(hours: 1)), '1:00:00');
    expect(_countdown(const Duration(hours: 8)), '8:00:00');
  });

  test('an eight hour token reads 7:59:12 rather than overflowing minutes', () {
    expect(
      useSmileIDSampleCountdown(
        _session(const Duration(hours: 8)).remaining(_now + 48 * 1000),
      ),
      '7:59:12',
    );
  });

  test(
    'the countdown pads both minutes and seconds once there is an hours part',
    () {
      expect(
        useSmileIDSampleCountdown(const Duration(hours: 1, seconds: 9)),
        '1:00:09',
      );
      expect(
        useSmileIDSampleCountdown(const Duration(hours: 1, minutes: 9)),
        '1:09:00',
      );
      expect(useSmileIDSampleCountdown(const Duration(seconds: 9)), '0:09');
      expect(
        useSmileIDSampleCountdown(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
      expect(useSmileIDSampleCountdown(Duration.zero), '0:00');
    },
  );

  test(
    'remaining never goes negative, and expiry holds from the deadline on',
    () {
      final UseSmileIDSampleTokenSession session = _session(
        const Duration(minutes: 15),
      );
      final int deadline = session.expiresAtMillis;
      expect(session.remaining(deadline + _hour), Duration.zero);
      expect(session.hasExpired(deadline - 1), isFalse);
      expect(session.hasExpired(deadline), isTrue);
    },
  );
}

String _countdown(Duration span) =>
    useSmileIDSampleCountdown(_session(span).remaining(_now));

UseSmileIDSampleTokenSession _session(Duration span) =>
    UseSmileIDSampleTokenSession(
      id: 'fixture',
      token: 'fixture.token.value',
      issuedAtMillis: _now,
      expiresAtMillis: _now + span.inMilliseconds,
      bindings: const UseSmileIDSampleTokenBindings(),
      environment: UseSmileIDSampleEnvironment.sandbox,
    );

const List<Duration> _spans = <Duration>[
  Duration(minutes: 15),
  Duration(hours: 1),
  Duration(hours: 8),
];
const int _now = 1755500000000;
const int _hour = 3600 * 1000;
const double _tolerance = 0.0001;
