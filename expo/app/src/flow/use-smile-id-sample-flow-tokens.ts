import {
  smileIDSampleBase64UrlEncode,
  smileIDSampleEnvironmentBaseUrl,
  type UseSmileIDSampleEnvironment,
  type UseSmileIDSampleSimulatedBindings,
  type UseSmileIDSampleSimulatedSpan,
} from '@smileid/sample-ui';

/// Structurally valid unsigned JWTs — fixtures the scenarios demand, never credentials.
export const smileIDSampleFlowToken = ({
  expired,
  nowMillis,
}: {
  readonly expired: boolean;
  readonly nowMillis: number;
}): string => {
  const exp = Math.floor(nowMillis / millisPerSecond) + (expired ? -validitySeconds : validitySeconds);
  return [header, `{"exp":${exp}}`, signature].map(smileIDSampleBase64UrlEncode).join('.');
};

/// What `badRefresh` hands back, so the failure path has something unusable to reject.
export const smileIDSampleMalformedToken = (): string => 'sample-not-a-jwt';

/// A simulated scan's unsigned token over the chosen span and bindings, with nonsense PII.
export const smileIDSampleSimulatedToken = ({
  span,
  bindings,
  environment,
  nowMillis,
}: {
  readonly span: UseSmileIDSampleSimulatedSpan;
  readonly bindings: UseSmileIDSampleSimulatedBindings;
  readonly environment: UseSmileIDSampleEnvironment;
  readonly nowMillis: number;
}): string => {
  const nowSeconds = Math.floor(nowMillis / millisPerSecond);
  const spanSeconds = span.spanMillis / millisPerSecond;
  // An ended span is minted in the past, the only way to reach the expiry gate.
  const issuedAt = span.ended ? nowSeconds - spanSeconds - endedLagSeconds : nowSeconds;
  const claims = [
    `"iat":${issuedAt}`,
    `"exp":${issuedAt + spanSeconds}`,
    // With a real claim's path, so the host match is exercised.
    `"api_url":"${smileIDSampleEnvironmentBaseUrl(environment)}${apiPath}"`,
  ];
  if (bindings.consent || bindings.userDetails) claims.push(payloadClaim(bindings, issuedAt));
  return [header, `{${claims.join(',')}}`, signature].map(smileIDSampleBase64UrlEncode).join('.');
};

const payloadClaim = (bindings: UseSmileIDSampleSimulatedBindings, issuedAtSeconds: number): string => {
  const fields: string[] = [];
  if (bindings.userDetails) {
    for (const field of vaultedFields) fields.push(`"${field}":"vault_${field}"`);
    // Plaintext on a Portal token too.
    fields.push('"country":"KE"', '"id_type":"NATIONAL_ID"');
  }
  if (bindings.consent) fields.push(consentClaim(issuedAtSeconds));
  return `"payload":{${fields.join(',')}}`;
};

/// All four subfields: a partial binding is a build error.
const consentClaim = (issuedAtSeconds: number): string => {
  const grantedAt = new Date(issuedAtSeconds * millisPerSecond).toISOString().replace(/\.\d{3}Z$/, 'Z');
  return (
    `"consent":{"granted":true,"granted_at":"${grantedAt}",` +
    `"notice_language":"en","notice_privacy_policy_url":"${privacyPolicyUrl}"}`
  );
};

const header = '{"alg":"none","typ":"JWT"}';
const signature = 'sample-signature';
const millisPerSecond = 1000;
const validitySeconds = 3600;
const endedLagSeconds = 60;
const apiPath = 'v3';
const privacyPolicyUrl = 'https://smile.id/privacy-policy';
const vaultedFields = ['given_names', 'last_name', 'email', 'phone_number', 'id_number'];
