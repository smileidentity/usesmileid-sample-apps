import { smileIDSampleEnvironments, type UseSmileIDSampleEnvironment } from './use-smile-id-sample-result';

/// The host each environment names; the SDK's own `SmileIDUrls` resolves to the same two.
export const smileIDSampleEnvironmentHosts: Readonly<Record<UseSmileIDSampleEnvironment, string>> = {
  sandbox: 'testapi.smileidentity.com',
  production: 'api.smileidentity.com',
};

/// What the simulated-scan chips read.
export const smileIDSampleEnvironmentLabels: Readonly<Record<UseSmileIDSampleEnvironment, string>> = {
  sandbox: 'Sandbox',
  production: 'Production',
};

/// Trailing slash, the form the SDK's own constants take.
export const smileIDSampleEnvironmentBaseUrl = (environment: UseSmileIDSampleEnvironment): string =>
  `https://${smileIDSampleEnvironmentHosts[environment]}/`;

// Scheme then authority, as java.net.URI reads it; a value without `//` names no host.
const AUTHORITY = /^[a-z][a-z0-9+.-]*:\/\/([^/?#]*)/i;
const HOST = /^[a-z0-9.-]+$/i;

/// The host an `api_url` names, so a rejection can say which one it saw. Null when the value carries none.
export const smileIDSampleApiUrlHost = (apiUrl: string | null | undefined): string | null => {
  const trimmed = apiUrl?.trim() ?? '';
  // Whitespace inside is not a URL at all, which is where java.net.URI throws.
  if (trimmed.length === 0 || /\s/.test(trimmed)) return null;
  const authority = AUTHORITY.exec(trimmed)?.[1];
  if (authority === undefined) return null;
  const host = authority.slice(authority.lastIndexOf('@') + 1).replace(/:\d*$/, '');
  return HOST.test(host) ? host.toLowerCase() : null;
};

/// A token's `api_url` onto an environment, on the parsed host: a real claim carries a `/v3` path, so a string compare misses silently.
export const smileIDSampleEnvironmentFor = (
  apiUrl: string | null | undefined,
): UseSmileIDSampleEnvironment | null => {
  const host = smileIDSampleApiUrlHost(apiUrl);
  return smileIDSampleEnvironments.find((environment) => smileIDSampleEnvironmentHosts[environment] === host) ?? null;
};
