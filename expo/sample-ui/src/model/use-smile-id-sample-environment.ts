import { smileIDSampleEnvironments, type UseSmileIDSampleEnvironment } from './use-smile-id-sample-result';

/// The host each environment names.
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

// Scheme then authority, as java.net.URI reads it.
const AUTHORITY = /^[a-z][a-z0-9+.-]*:\/\/([^/?#]*)/i;
const HOST = /^[a-z0-9.-]+$/i;

/// The host an `api_url` names, or null.
export const smileIDSampleApiUrlHost = (apiUrl: string | null | undefined): string | null => {
  const trimmed = apiUrl?.trim() ?? '';
  // Whitespace inside is where java.net.URI throws.
  if (trimmed.length === 0 || /\s/.test(trimmed)) return null;
  const authority = AUTHORITY.exec(trimmed)?.[1];
  if (authority === undefined) return null;
  const host = authority.slice(authority.lastIndexOf('@') + 1).replace(/:\d*$/, '');
  return HOST.test(host) ? host.toLowerCase() : null;
};

/// A token's `api_url` onto an environment, by its parsed host.
export const smileIDSampleEnvironmentFor = (
  apiUrl: string | null | undefined,
): UseSmileIDSampleEnvironment | null => {
  const host = smileIDSampleApiUrlHost(apiUrl);
  return smileIDSampleEnvironments.find((environment) => smileIDSampleEnvironmentHosts[environment] === host) ?? null;
};
