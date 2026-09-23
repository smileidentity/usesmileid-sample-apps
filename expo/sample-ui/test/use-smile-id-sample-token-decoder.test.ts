import { createHash } from 'node:crypto';

import { smileIDSampleProductFrom } from '../src/model/use-smile-id-sample-product';
import {
  smileIDSampleBase64UrlBytes,
  smileIDSampleBase64UrlEncode,
  smileIDSampleSha256,
  smileIDSampleUtf8Bytes,
  smileIDSampleUtf8Text,
} from '../src/state/use-smile-id-sample-token-bytes';
import {
  smileIDSampleBindsIdDetails,
  smileIDSampleBindsRequiredUserDetails,
  smileIDSampleConsentIsComplete,
  smileIDSampleDecodeToken,
  smileIDSampleTokenSession,
  type UseSmileIDSampleTokenBindings,
} from '../src/state/use-smile-id-sample-token-decoder';

/// The same cases as Android's and iOS's decoder tests, so no platform can quietly disagree about what "bound" means.
const IAT = 1_755_500_000;
const EXP = 1_755_500_900;
const GRANTED_AT = '2026-08-18T09:00:00Z';
const HEADER = '{"alg":"none","typ":"JWT"}';
const SANDBOX_URL = '"api_url":"https://testapi.smileidentity.com/v3"';

const base64Url = (text: string) => Buffer.from(text, 'utf8').toString('base64url');
const jwt = (claims: string) => [HEADER, claims, 'sample-signature'].map(base64Url).join('.');
const token = () => jwt(`{"iat":${IAT},"exp":${EXP},${SANDBOX_URL}}`);
const tokenWithApiUrl = (claim: string) => jwt(`{"iat":${IAT},"exp":${EXP},${claim}}`);
const decode = (candidate: string) => smileIDSampleDecodeToken(candidate);
const session = (candidate: string) => smileIDSampleTokenSession(candidate);
const rejection = (candidate: string) => {
  const decoded = decode(candidate);
  if (decoded.kind !== 'rejected') throw new Error('expected a rejection');
  return decoded.reason;
};
const bindings = (payloadFields: string): UseSmileIDSampleTokenBindings =>
  session(jwt(`{"iat":${IAT},"exp":${EXP},${SANDBOX_URL},"payload":{${payloadFields}}}`))!.bindings;
const quoted = (value: string | null) => (value === null ? 'null' : `"${value}"`);
const consent = ({
  granted = 'true',
  grantedAt = GRANTED_AT as string | null,
  language = 'en' as string | null,
  policyUrl = 'https://smile.id/privacy-policy' as string | null,
} = {}) =>
  `"consent":{"granted":${granted},"granted_at":${quoted(grantedAt)},` +
  `"notice_language":${quoted(language)},"notice_privacy_policy_url":${quoted(policyUrl)}}`;
const product = (id: string) => smileIDSampleProductFrom(id)!;

describe('the token decoder', () => {
  it('takes three base64url segments or it is not a token', () => {
    for (const candidate of [
      'not-a-jwt',
      'two.segments',
      'four.of.these.segments',
      'header..signature',
      'header.pay load.signature',
      'header.payload+slash.signature',
    ]) {
      expect(decode(candidate).kind).toBe('rejected');
    }
  });

  it('trims surrounding whitespace rather than rejecting it', () => {
    expect(session(`  ${token()}\n`)).not.toBeNull();
  });

  it('rejects a payload segment that is not base64url JSON', () => {
    expect(decode('aGVhZGVy.@@@@.c2ln').kind).toBe('rejected');
    expect(decode(jwt('[1,2,3]')).kind).toBe('rejected');
    expect(decode(jwt('{"exp":')).kind).toBe('rejected');
  });

  it('requires both time claims, with exp after iat', () => {
    expect(decode(jwt(`{"iat":${IAT}}`)).kind).toBe('rejected');
    expect(decode(jwt(`{"exp":${EXP}}`)).kind).toBe('rejected');
    expect(decode(jwt(`{"iat":${EXP},"exp":${IAT}}`)).kind).toBe('rejected');
    expect(decode(jwt(`{"iat":${IAT},"exp":"${EXP}"}`)).kind).toBe('rejected');
  });

  it('names the structure that failed and never the token', () => {
    const candidate = jwt(`{"iat":${IAT}}`);
    const reason = rejection(candidate);
    expect(reason).toContain('exp');
    expect(reason).not.toContain(candidate.split('.')[1]);
  });

  it('turns epoch seconds into the absolute deadline in millis', () => {
    const decoded = session(token())!;
    expect(decoded.issuedAtMillis).toBe(IAT * 1000);
    expect(decoded.expiresAtMillis).toBe(EXP * 1000);
  });

  it('uses the jti as the handle when the token carries one', () => {
    expect(session(jwt(`{"iat":${IAT},"exp":${EXP},${SANDBOX_URL},"jti":"sess_7f2"}`))!.id).toBe('sess_7f2');
  });

  it('falls back to a short digest, never a prefix of the credential', () => {
    const candidate = token();
    const decoded = session(candidate)!;
    expect(decoded.id).toMatch(/^[0-9a-f]{8}$/);
    expect(candidate.startsWith(decoded.id)).toBe(false);
    expect(candidate).not.toContain(decoded.id);
    expect(session(candidate)!.id).toBe(decoded.id);
    // The first four bytes of SHA-256, so the handle matches the other three apps for the same token.
    expect(decoded.id).toBe(createHash('sha256').update(candidate).digest('hex').slice(0, 8));
  });

  it('keeps the token out of anything that serialises the session', () => {
    const decoded = session(token())!;
    expect(decoded.token).toBe(token());
    expect(JSON.stringify(decoded)).not.toContain(decoded.token);
    expect(Object.keys(decoded)).not.toContain('token');
  });

  it('maps each known host to its environment, whatever the scheme, port, path or case', () => {
    const cases: [string, 'sandbox' | 'production'][] = [
      ['https://testapi.smileidentity.com/v3', 'sandbox'],
      ['https://testapi.smileidentity.com/', 'sandbox'],
      ['https://testapi.smileidentity.com', 'sandbox'],
      ['HTTPS://TestApi.SmileIdentity.COM/v3', 'sandbox'],
      ['https://api.smileidentity.com/', 'production'],
      ['https://api.smileidentity.com/v3', 'production'],
      ['http://api.smileidentity.com/v3', 'production'],
      ['https://api.smileidentity.com:443/v3', 'production'],
    ];
    for (const [url, expected] of cases) {
      expect(session(tokenWithApiUrl(`"api_url":"${url}"`))?.environment).toBe(expected);
    }
  });

  it('refuses an unrecognised host rather than falling back, and names it', () => {
    expect(rejection(tokenWithApiUrl('"api_url":"https://api.smileidentity.com.evil.test/v3"'))).toContain(
      'api.smileidentity.com.evil.test',
    );
  });

  it('does not take a host that only looks like one of ours', () => {
    for (const url of [
      'https://smileidentity.com/v3',
      'https://api.smileidentity.com.br/v3',
      'https://testapi.smileidentity.co/v3',
      'testapi.smileidentity.com/v3',
      'https://:8080/v3',
    ]) {
      expect(decode(tokenWithApiUrl(`"api_url":"${url}"`)).kind).toBe('rejected');
    }
  });

  it('says a malformed api_url is not a URL without pretending to name a host', () => {
    expect(rejection(tokenWithApiUrl('"api_url":"not a url at all"'))).toContain('not a URL');
  });

  it('refuses an absent, blank or non-string api_url', () => {
    for (const claim of ['"jti":"sess_7f2"', '"api_url":""', '"api_url":"  "', '"api_url":42']) {
      expect(rejection(tokenWithApiUrl(claim))).toContain('api_url');
    }
  });

  it('binds a field only when the claim carries it as a non-empty string', () => {
    const bound = bindings('"given_names":"vault_given_names","last_name":"","email":42,"phone_number":null');
    expect(bound.givenNames).toBe(true);
    expect(bound.lastName).toBe(false);
    expect(bound.email).toBe(false);
    expect(bound.phoneNumber).toBe(false);
  });

  it('does not take an object or array in a user-detail field as a binding', () => {
    const bound = bindings('"given_names":{"vault":"x"},"last_name":["x"]');
    expect(bound.givenNames).toBe(false);
    expect(bound.lastName).toBe(false);
  });

  it('reads the two plaintext claims and the ID number reference', () => {
    const bound = bindings('"country":"KE","id_type":"NATIONAL_ID","id_number":"pii_fixture01"');
    expect(bound.country).toBe('KE');
    expect(bound.idType).toBe('NATIONAL_ID');
    expect(bound.idNumberReference).toBe('pii_fixture01');
  });

  it('reads a blank value claim as absent, unlike the presence flags', () => {
    const bound = bindings('"country":" ","id_type":"","id_number":"  "');
    expect(bound.country).toBeNull();
    expect(bound.idType).toBeNull();
    expect(bound.idNumberReference).toBeNull();
  });

  it('needs country, ID type and the ID number reference before a KYC form is skipped', () => {
    const bound: UseSmileIDSampleTokenBindings = { country: 'KE', idType: 'NATIONAL_ID', idNumberReference: 'pii_1' };
    for (const id of ['enhancedKyc', 'biometricKyc']) {
      expect(smileIDSampleBindsIdDetails(bound, product(id))).toBe(true);
      expect(smileIDSampleBindsIdDetails({ ...bound, idNumberReference: null }, product(id))).toBe(false);
      expect(smileIDSampleBindsIdDetails({ ...bound, idType: null }, product(id))).toBe(false);
      expect(smileIDSampleBindsIdDetails({ ...bound, country: null }, product(id))).toBe(false);
    }
  });

  it('needs country and ID type for both document products, and no ID number', () => {
    const bound: UseSmileIDSampleTokenBindings = { country: 'KE', idType: 'NATIONAL_ID' };
    for (const id of ['documentVerification', 'enhancedDocumentVerification']) {
      expect(smileIDSampleBindsIdDetails(bound, product(id))).toBe(true);
      expect(smileIDSampleBindsIdDetails({ ...bound, idType: null }, product(id))).toBe(false);
      expect(smileIDSampleBindsIdDetails({ ...bound, country: null }, product(id))).toBe(false);
    }
  });

  it('never sends a product that submits no ID parameters to the form', () => {
    expect(smileIDSampleBindsIdDetails({}, product('smartSelfieEnrollment'))).toBe(true);
    expect(smileIDSampleBindsIdDetails({}, product('smartSelfieAuth'))).toBe(true);
  });

  it('takes an absent or empty consent object as no consent binding', () => {
    expect(bindings('"given_names":"x"').consent).toBeNull();
    expect(bindings('"consent":{}').consent).toBeNull();
  });

  it('never counts granted false or non-boolean toward a consent binding', () => {
    expect(smileIDSampleConsentIsComplete(bindings(consent({ granted: 'false' })).consent)).toBe(false);
    expect(smileIDSampleConsentIsComplete(bindings(consent({ granted: '"true"' })).consent)).toBe(false);
    expect(bindings(consent({ granted: 'false' })).consent?.granted).toBeNull();
  });

  it('completes consent only with granted true and all three subfields non-blank', () => {
    expect(smileIDSampleConsentIsComplete(bindings(consent()).consent)).toBe(true);
    expect(smileIDSampleConsentIsComplete(bindings(consent({ grantedAt: null })).consent)).toBe(false);
    expect(smileIDSampleConsentIsComplete(bindings(consent({ language: ' ' })).consent)).toBe(false);
    expect(smileIDSampleConsentIsComplete(bindings(consent({ policyUrl: '' })).consent)).toBe(false);
  });

  it('reads a non-string consent subfield as absent', () => {
    const read = bindings('"consent":{"granted":true,"granted_at":42,"notice_language":"en"}').consent;
    expect(read?.grantedAt).toBeNull();
    expect(smileIDSampleConsentIsComplete(read)).toBe(false);
  });

  it('requires both names plus one contact field', () => {
    const names: UseSmileIDSampleTokenBindings = { givenNames: true, lastName: true };
    expect(smileIDSampleBindsRequiredUserDetails(names)).toBe(false);
    expect(smileIDSampleBindsRequiredUserDetails({ ...names, email: true })).toBe(true);
    expect(smileIDSampleBindsRequiredUserDetails({ ...names, phoneNumber: true })).toBe(true);
    expect(smileIDSampleBindsRequiredUserDetails({ ...names, givenNames: false, email: true })).toBe(false);
    expect(smileIDSampleBindsRequiredUserDetails({ email: true, phoneNumber: true })).toBe(false);
  });

  it('leaves a token with a payload of the wrong shape usable and unbound', () => {
    expect(session(jwt(`{"iat":${IAT},"exp":${EXP},${SANDBOX_URL},"payload":"nonsense"}`))!.bindings).toEqual({});
  });

  it('rejects nesting past the reader depth cap rather than crashing', () => {
    const deep = '['.repeat(200) + ']'.repeat(200);
    expect(decode(jwt(`{"iat":${IAT},"exp":${EXP},${SANDBOX_URL},"payload":${deep}}`)).kind).toBe('rejected');
  });

  it('reads the partner id, and a blank one as absent', () => {
    expect(session(jwt(`{"iat":${IAT},"exp":${EXP},${SANDBOX_URL},"partner_id":"p_fixture"}`))!.partnerId).toBe(
      'p_fixture',
    );
    expect(session(jwt(`{"iat":${IAT},"exp":${EXP},${SANDBOX_URL},"partner_id":" "}`))!.partnerId).toBeNull();
  });
});

describe('the byte helpers', () => {
  it('hash to the published SHA-256 vectors', () => {
    const hex = (text: string) =>
      Array.from(smileIDSampleSha256(smileIDSampleUtf8Bytes(text)))
        .map((byte) => byte.toString(16).padStart(2, '0'))
        .join('');
    expect(hex('abc')).toBe('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    expect(hex('')).toBe('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
    const long = 'x'.repeat(1000);
    expect(hex(long)).toBe(createHash('sha256').update(long).digest('hex'));
  });

  it('round-trip base64url and UTF-8 the way Node does', () => {
    for (const text of ['', 'a', 'ab', 'abc', '{"given_names":"Wanjirũ"}', '✓ 🙂']) {
      expect(smileIDSampleBase64UrlEncode(text)).toBe(Buffer.from(text, 'utf8').toString('base64url'));
      expect(smileIDSampleUtf8Text(smileIDSampleBase64UrlBytes(base64Url(text))!)).toBe(text);
    }
    expect(smileIDSampleBase64UrlBytes('a')).toBeNull();
  });
});
