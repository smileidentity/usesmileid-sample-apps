import type { UseSmileIDSampleEnvironment } from '../model/use-smile-id-sample-result';
import type { UseSmileIDSampleTokenBindings } from './use-smile-id-sample-token-decoder';

/// A linked session, held as an absolute deadline; only the decoder builds one.
export type UseSmileIDSampleTokenSession = {
  /// A display handle: the `jti`, else a digest; never a prefix.
  readonly id: string;
  readonly token: string;
  readonly issuedAtMillis: number;
  readonly expiresAtMillis: number;
  readonly bindings: UseSmileIDSampleTokenBindings;
  /// From the token's `partner_id`, which wins over the profile; never logged.
  readonly partnerId: string | null;
  /// From the token's `api_url`.
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

/// 1 fresh to 0 expired over the token's own span.
export const smileIDSampleSessionProgress = (session: UseSmileIDSampleTokenSession, nowMillis: number): number => {
  const span = Math.max(session.expiresAtMillis - session.issuedAtMillis, 1);
  return Math.min(Math.max(smileIDSampleSessionRemaining(session, nowMillis) / span, 0), 1);
};

const MILLIS_PER_SECOND = 1000;
const SECONDS_PER_MINUTE = 60;
const SECONDS_PER_HOUR = 3600;

const pad = (value: number) => String(value).padStart(2, '0');

/// `m:ss`, with an hours part past an hour.
export const smileIDSampleCountdown = (remainingMillis: number): string => {
  const total = Math.floor(Math.max(remainingMillis, 0) / MILLIS_PER_SECOND);
  const hours = Math.floor(total / SECONDS_PER_HOUR);
  const minutes = Math.floor((total % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE);
  const seconds = total % SECONDS_PER_MINUTE;
  return hours > 0 ? `${hours}:${pad(minutes)}:${pad(seconds)}` : `${minutes}:${pad(seconds)}`;
};
