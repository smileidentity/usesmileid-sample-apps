/// Structurally valid unsigned JWTs — fixtures the scenarios demand, never credentials.
export const smileIDSampleFlowToken = ({
  expired,
  nowMillis,
}: {
  readonly expired: boolean;
  readonly nowMillis: number;
}): string => {
  const exp = Math.floor(nowMillis / millisPerSecond) + (expired ? -validitySeconds : validitySeconds);
  return [header, `{"exp":${exp}}`, signature].map(base64Url).join('.');
};

/// What `badRefresh` hands back, so the failure path has something unusable to reject.
export const smileIDSampleMalformedToken = (): string => 'sample-not-a-jwt';

const base64Url = (value: string): string =>
  // Hermes has no Buffer, and the padding is what a JWT omits.
  globalThis
    .btoa(value)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

const header = '{"alg":"none","typ":"JWT"}';
const signature = 'sample-signature';
const millisPerSecond = 1000;
const validitySeconds = 3600;
