import type { UseSmileIDSampleEnvironment } from '../model/use-smile-id-sample-result';
import { smileIDSampleTokenIsUnsigned } from '../state/use-smile-id-sample-token-decoder';

/// The ID form's lists as raw bodies, so the network stays in the shell and one decoder reads live and fixture.
export type UseSmileIDSampleCatalogueSource = {
  /// `GET /v3/services/supported_id_types`, every country.
  supportedIdTypes: (environment: UseSmileIDSampleEnvironment) => Promise<string>;
  /// `GET /v3/services/supported_documents?locale=…`.
  supportedDocuments: (environment: UseSmileIDSampleEnvironment, locale: string) => Promise<string>;
  /// `GET /v3/services/config?product=enhanced_document_verification&locale=…`, under the session's `token`.
  servicesConfig: (environment: UseSmileIDSampleEnvironment, token: string, locale: string) => Promise<string>;
};

/// A response that is not a 2xx, so the store can name a 401 or 403 in the error state.
export class UseSmileIDSampleCatalogueHttpError extends Error {
  constructor(readonly status: number) {
    super(`HTTP ${status}`);
  }
}

/// A live source that answers a simulated session's configuration from the fixture: the server refuses an unsigned token.
export const smileIDSampleSessionAwareCatalogueSource = (
  live: UseSmileIDSampleCatalogueSource,
  fixture: UseSmileIDSampleCatalogueSource,
): UseSmileIDSampleCatalogueSource => ({
  supportedIdTypes: live.supportedIdTypes,
  supportedDocuments: live.supportedDocuments,
  servicesConfig: (environment, token, locale) =>
    (smileIDSampleTokenIsUnsigned(token) ? fixture : live).servicesConfig(environment, token, locale),
});

/// `catalogue=fixture`: the bodies from `spec/catalogue-fixture.json`, with no network.
export const smileIDSampleFixtureCatalogueSource = (fixture: {
  readonly supported_id_types: unknown;
  readonly supported_documents: unknown;
  readonly services_config: unknown;
}): UseSmileIDSampleCatalogueSource => ({
  supportedIdTypes: async () => JSON.stringify(fixture.supported_id_types),
  supportedDocuments: async () => JSON.stringify(fixture.supported_documents),
  servicesConfig: async () => JSON.stringify(fixture.services_config),
});

/// `catalogue=unreachable`: every call fails at once, which is how a flow reaches the error state.
export const smileIDSampleUnreachableCatalogueSource: UseSmileIDSampleCatalogueSource = {
  supportedIdTypes: () => Promise.reject(new Error('catalogue=unreachable')),
  supportedDocuments: () => Promise.reject(new Error('catalogue=unreachable')),
  servicesConfig: () => Promise.reject(new Error('catalogue=unreachable')),
};
