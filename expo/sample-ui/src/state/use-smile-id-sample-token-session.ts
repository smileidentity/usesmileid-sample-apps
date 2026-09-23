import type { UseSmileIDSampleEnvironment } from '../model/use-smile-id-sample-result';
import type { UseSmileIDSampleTokenBindings } from './use-smile-id-sample-token-decoder';

/// A linked session, held as an absolute deadline because a counter restarts wrong after process death. Only the decoder builds one.
export type UseSmileIDSampleTokenSession = {
  /// A display handle — the token's `jti`, else a digest of it. Never a prefix of the credential.
  readonly id: string;
  readonly token: string;
  readonly issuedAtMillis: number;
  readonly expiresAtMillis: number;
  readonly bindings: UseSmileIDSampleTokenBindings;
  /// From the token's own `partner_id`, which wins over the profile. Never logged.
  readonly partnerId: string | null;
  /// From the token's own `api_url`; the decoder refuses a token it cannot place.
  readonly environment: UseSmileIDSampleEnvironment;
};

/// A session that ran out, remembered without its credential.
export type UseSmileIDSampleEndedSession = {
  readonly id: string;
  readonly endedAtMillis: number;
};

/// Milliseconds left, never negative.
export const smileIDSampleSessionRemaining = (session: UseSmileIDSampleTokenSession, nowMillis: number): number =>
  Math.max(session.expiresAtMillis - nowMillis, 0);

/// Expiry is the deadline itself.
export const smileIDSampleSessionHasExpired = (session: UseSmileIDSampleTokenSession, nowMillis: number): boolean =>
  nowMillis >= session.expiresAtMillis;

/// 1 fresh to 0 expired over the token's own span; a zero span reads as spent rather than NaN.
export const smileIDSampleSessionProgress = (session: UseSmileIDSampleTokenSession, nowMillis: number): number => {
  const span = Math.max(session.expiresAtMillis - session.issuedAtMillis, 1);
  return Math.min(Math.max(smileIDSampleSessionRemaining(session, nowMillis) / span, 0), 1);
};

const pad = (value: number) => String(value).padStart(2, '0');

/// `m:ss`, growing an hours part when the span needs one — an 8h token reads 7:59:12, not 479:12.
export const smileIDSampleCountdown = (remainingMillis: number): string => {
  const total = Math.floor(Math.max(remainingMillis, 0) / 1000);
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;
  return hours > 0 ? `${hours}:${pad(minutes)}:${pad(seconds)}` : `${minutes}:${pad(seconds)}`;
};
