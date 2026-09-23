import type { UseSmileIDSampleProduct } from '../model/use-smile-id-sample-product';
import { smileIDSampleApiUrlHost, smileIDSampleEnvironmentFor } from '../model/use-smile-id-sample-environment';
import {
  smileIDSampleBase64UrlBytes,
  smileIDSampleSha256,
  smileIDSampleUtf8Bytes,
  smileIDSampleUtf8Text,
} from './use-smile-id-sample-token-bytes';
import type { UseSmileIDSampleTokenSession } from './use-smile-id-sample-token-session';

/// The consent bound into the token; `granted` is true or absent.
export type UseSmileIDSampleTokenConsent = {
  readonly granted: boolean | null;
  readonly grantedAt: string | null;
  readonly noticeLanguage: string | null;
  readonly noticePrivacyPolicyUrl: string | null;
};

/// What a v3 token binds: presence for vaulted PII, plaintext `country` and `idType`.
export type UseSmileIDSampleTokenBindings = {
  readonly givenNames?: boolean;
  readonly lastName?: boolean;
  readonly email?: boolean;
  readonly phoneNumber?: boolean;
  readonly consent?: UseSmileIDSampleTokenConsent | null;
  readonly country?: string | null;
  readonly idType?: string | null;
  /// The vault reference standing in for the ID number.
  readonly idNumberReference?: string | null;
  /// A webhook URL or `callback_` id the server injects.
  readonly callbackUrl?: string | null;
};

/// Either the session a token describes, or why it is not one.
export type UseSmileIDSampleTokenDecode =
  | { readonly kind: 'decoded'; readonly session: UseSmileIDSampleTokenSession }
  /// Names what failed; never a value, bar the public `api_url` host.
  | { readonly kind: 'rejected'; readonly reason: string };

/// True when the token alone satisfies consent.
export const smileIDSampleConsentIsComplete = (consent: UseSmileIDSampleTokenConsent | null | undefined): boolean =>
  consent != null &&
  consent.granted === true &&
  nonBlank(consent.grantedAt) &&
  nonBlank(consent.noticeLanguage) &&
  nonBlank(consent.noticePrivacyPolicyUrl);

/// The SDK's internal `bindsRequiredUserDetails`: both names plus one contact.
export const smileIDSampleBindsRequiredUserDetails = (
  bindings: UseSmileIDSampleTokenBindings | null | undefined,
): boolean =>
  bindings?.givenNames === true && bindings.lastName === true && (bindings.email === true || bindings.phoneNumber === true);

/// Whether the token carries every ID parameter `product` submits.
export const smileIDSampleBindsIdDetails = (
  bindings: UseSmileIDSampleTokenBindings | null | undefined,
  product: UseSmileIDSampleProduct,
): boolean => {
  switch (product.id) {
    case 'enhancedKyc':
    case 'biometricKyc':
      return nonBlank(bindings?.country) && nonBlank(bindings?.idType) && nonBlank(bindings?.idNumberReference);
    case 'documentVerification':
    case 'enhancedDocumentVerification':
      return nonBlank(bindings?.country) && nonBlank(bindings?.idType);
    default:
      return true;
  }
};

/// Reads a token's claims; decoding is not verification.
export const smileIDSampleDecodeToken = (token: string): UseSmileIDSampleTokenDecode => {
  const trimmed = token.trim();
  const segments = trimmed.split('.');
  if (segments.length !== SEGMENTS || segments.some((segment) => !BASE64_URL.test(segment))) {
    return reject('A token is three dot-separated base64url segments; this is not.');
  }
  const bytes = smileIDSampleBase64UrlBytes(segments[1]!);
  if (bytes === null) return reject("The token's payload segment is not base64url.");
  const claims = parseObject(smileIDSampleUtf8Text(bytes));
  if (claims === null) return reject("The token's payload segment is not a JSON object.");
  const issuedAt = seconds(claims.iat);
  if (issuedAt === null) return reject('The token carries no numeric iat claim.');
  const expires = seconds(claims.exp);
  if (expires === null) return reject('The token carries no numeric exp claim.');
  if (expires <= issuedAt) return reject("The token's exp claim is not after its iat claim.");
  // Refused, not defaulted: a sandbox fallback sends a production token to the wrong host.
  const apiUrl = valueOf(claims.api_url);
  if (apiUrl === null) {
    return reject('The token carries no api_url claim, so nothing says which environment it was minted for.');
  }
  const environment = smileIDSampleEnvironmentFor(apiUrl);
  if (environment === null) {
    const host = smileIDSampleApiUrlHost(apiUrl);
    return reject(
      host === null
        ? "The token's api_url is not a URL, so it names no environment."
        : `The token's api_url names ${host}, which is not a Smile ID environment.`,
    );
  }
  const session: UseSmileIDSampleTokenSession = {
    id: valueOf(claims.jti) ?? digest(trimmed),
    token: trimmed,
    issuedAtMillis: issuedAt * MILLIS_PER_SECOND,
    expiresAtMillis: expires * MILLIS_PER_SECOND,
    bindings: bindingsOf(claims.payload),
    partnerId: valueOf(claims.partner_id),
    environment,
  };
  // Not enumerable, so JSON or a log never carries the credential.
  Object.defineProperty(session, 'token', { value: trimmed, enumerable: false });
  return { kind: 'decoded', session };
};

/// The session a token describes, or null.
export const smileIDSampleTokenSession = (token: string): UseSmileIDSampleTokenSession | null => {
  const decoded = smileIDSampleDecodeToken(token);
  return decoded.kind === 'decoded' ? decoded.session : null;
};

type Json = null | boolean | number | string | Json[] | { [key: string]: Json };
type JsonObject = { [key: string]: Json };

const SEGMENTS = 3;
const MILLIS_PER_SECOND = 1000;
const HANDLE_BYTES = 4;
/// Android's reader cap, so every app refuses the same depth.
const MAX_DEPTH = 32;
const BASE64_URL = /^[A-Za-z0-9_-]+$/;

const reject = (reason: string): UseSmileIDSampleTokenDecode => ({ kind: 'rejected', reason });

const nonBlank = (value: string | null | undefined): boolean => value != null && value.trim().length > 0;

const isObject = (value: Json | undefined): value is JsonObject =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const deeperThan = (value: Json, depth: number): boolean => {
  if (depth > MAX_DEPTH) return true;
  if (Array.isArray(value)) return value.some((item) => deeperThan(item, depth + 1));
  if (isObject(value)) return Object.values(value).some((item) => deeperThan(item, depth + 1));
  return false;
};

const parseObject = (text: string): JsonObject | null => {
  try {
    const parsed = JSON.parse(text) as Json;
    return isObject(parsed) && !deeperThan(parsed, 0) ? parsed : null;
  } catch {
    return null;
  }
};

const seconds = (value: Json | undefined): number | null =>
  typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : null;

/// A value claim, absent when blank.
const valueOf = (value: Json | undefined): string | null => (typeof value === 'string' && nonBlank(value) ? value : null);

/// Bound iff a non-empty string.
const binds = (value: Json | undefined): boolean => typeof value === 'string' && value.length > 0;

const bindingsOf = (payload: Json | undefined): UseSmileIDSampleTokenBindings => {
  // A payload of the wrong shape leaves the token unbound, as the SDK degrades it.
  if (!isObject(payload)) return {};
  return {
    givenNames: binds(payload.given_names),
    lastName: binds(payload.last_name),
    email: binds(payload.email),
    phoneNumber: binds(payload.phone_number),
    consent: consentOf(payload.consent),
    country: valueOf(payload.country),
    idType: valueOf(payload.id_type),
    idNumberReference: valueOf(payload.id_number),
    callbackUrl: valueOf(payload.callback_url),
  };
};

/// An empty consent object is no consent.
const consentOf = (value: Json | undefined): UseSmileIDSampleTokenConsent | null => {
  if (!isObject(value) || Object.keys(value).length === 0) return null;
  const text = (field: Json | undefined) => (typeof field === 'string' ? field : null);
  return {
    granted: value.granted === true ? true : null,
    grantedAt: text(value.granted_at),
    noticeLanguage: text(value.notice_language),
    noticePrivacyPolicyUrl: text(value.notice_privacy_policy_url),
  };
};

/// A display handle: the first bytes of its SHA-256, never a prefix.
const digest = (token: string): string =>
  Array.from(smileIDSampleSha256(smileIDSampleUtf8Bytes(token)).subarray(0, HANDLE_BYTES))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
