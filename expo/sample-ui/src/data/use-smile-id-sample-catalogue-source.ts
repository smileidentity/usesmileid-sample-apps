import type { UseSmileIDSampleEnvironment } from '../model/use-smile-id-sample-result';

/// The ID form's two lists as raw response bodies, so the network stays in the shell and one decoder reads live and fixture alike.
export type UseSmileIDSampleCatalogueSource = {
  /// `GET /v3/services/supported_id_types`, every country.
  supportedIdTypes: (environment: UseSmileIDSampleEnvironment) => Promise<string>;
  /// `GET /v3/services/supported_documents?continent=AFRICA&locale=…`.
  supportedDocuments: (environment: UseSmileIDSampleEnvironment, locale: string) => Promise<string>;
};

/// `catalogue=fixture`: the two bodies from `spec/catalogue-fixture.json`, with no network.
export const smileIDSampleFixtureCatalogueSource = (fixture: {
  readonly supported_id_types: unknown;
  readonly supported_documents: unknown;
}): UseSmileIDSampleCatalogueSource => ({
  supportedIdTypes: async () => JSON.stringify(fixture.supported_id_types),
  supportedDocuments: async () => JSON.stringify(fixture.supported_documents),
});

/// `catalogue=unreachable`: every call fails at once, which is how a flow reaches the error state.
export const smileIDSampleUnreachableCatalogueSource: UseSmileIDSampleCatalogueSource = {
  supportedIdTypes: () => Promise.reject(new Error('catalogue=unreachable')),
  supportedDocuments: () => Promise.reject(new Error('catalogue=unreachable')),
};
