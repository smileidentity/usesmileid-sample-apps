import {
  smileIDSampleCountdown,
  smileIDSampleSessionHasExpired,
  smileIDSampleSessionProgress,
  smileIDSampleSessionRemaining,
  type UseSmileIDSampleTokenSession,
} from '../src/state/use-smile-id-sample-token-session';

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const ISSUED = 1_755_500_000_000;

const sessionOf = (spanMillis: number): UseSmileIDSampleTokenSession => ({
  id: 'a1b2c3d4',
  token: 'unused',
  issuedAtMillis: ISSUED,
  expiresAtMillis: ISSUED + spanMillis,
  bindings: {},
  partnerId: null,
  environment: 'sandbox',
});

describe('the token session', () => {
  it('measures the ring over the token own span, not a fixed five minutes', () => {
    for (const span of [15 * MINUTE, HOUR, 8 * HOUR]) {
      const session = sessionOf(span);
      expect(smileIDSampleSessionProgress(session, ISSUED)).toBe(1);
      expect(smileIDSampleSessionProgress(session, ISSUED + span / 2)).toBeCloseTo(0.5);
    }
  });

  it('leaves an eight hour token most of its ring an hour in', () => {
    expect(smileIDSampleSessionProgress(sessionOf(8 * HOUR), ISSUED + HOUR)).toBeCloseTo(7 / 8);
  });

  it('clamps progress either side of the span', () => {
    const session = sessionOf(15 * MINUTE);
    expect(smileIDSampleSessionProgress(session, ISSUED - HOUR)).toBe(1);
    expect(smileIDSampleSessionProgress(session, ISSUED + HOUR)).toBe(0);
  });

  it('reads m:ss under an hour and h:mm:ss above it, fresh at each Portal span', () => {
    expect(smileIDSampleCountdown(smileIDSampleSessionRemaining(sessionOf(15 * MINUTE), ISSUED))).toBe('15:00');
    expect(smileIDSampleCountdown(smileIDSampleSessionRemaining(sessionOf(HOUR), ISSUED))).toBe('1:00:00');
    expect(smileIDSampleCountdown(smileIDSampleSessionRemaining(sessionOf(8 * HOUR), ISSUED))).toBe('8:00:00');
  });

  it('reads an eight hour token as 7:59:12 rather than overflowing minutes', () => {
    expect(smileIDSampleCountdown(8 * HOUR - 48_000)).toBe('7:59:12');
  });

  it('pads both minutes and seconds once there is an hours part', () => {
    expect(smileIDSampleCountdown(HOUR + 5 * MINUTE + 7_000)).toBe('1:05:07');
    expect(smileIDSampleCountdown(59 * MINUTE + 5_000)).toBe('59:05');
  });

  it('floors rather than rounds, so it never shows time that has gone', () => {
    expect(smileIDSampleCountdown(59_999)).toBe('0:59');
  });

  it('reads a zero span as spent rather than as NaN', () => {
    expect(smileIDSampleSessionProgress(sessionOf(0), ISSUED)).toBe(0);
  });

  it('expires at the deadline itself, and never counts below zero', () => {
    const session = sessionOf(15 * MINUTE);
    expect(smileIDSampleSessionHasExpired(session, session.expiresAtMillis - 1)).toBe(false);
    expect(smileIDSampleSessionHasExpired(session, session.expiresAtMillis)).toBe(true);
    expect(smileIDSampleSessionRemaining(session, session.expiresAtMillis + HOUR)).toBe(0);
    expect(smileIDSampleCountdown(-5_000)).toBe('0:00');
  });
});
