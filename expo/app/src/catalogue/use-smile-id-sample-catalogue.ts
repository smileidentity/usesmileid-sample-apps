import {
  createSmileIDSampleCatalogueStore,
  smileIDSampleEnvironmentBaseUrl,
  smileIDSampleFixtureCatalogueSource,
  smileIDSampleUnreachableCatalogueSource,
  type UseSmileIDSampleCatalogueMode,
  type UseSmileIDSampleCatalogueSource,
  type UseSmileIDSampleCatalogueStore,
  type UseSmileIDSampleEnvironment,
  type UseSmileIDSampleTokenSession,
} from '@smileid/sample-ui';

// A copy of spec/catalogue-fixture.json: Metro cannot reach spec/, and verify.sh fails if the copy drifts.
import fixture from '../../assets/catalogue-fixture.json';

// The picker lists African countries only; the API's continent filter is how it asks for them.
const CONTINENT = 'AFRICA';

const bodyOf = async (url: string): Promise<string> => {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.text();
};

/// The two unauthenticated catalogue endpoints; no token is sent, both are the same for every partner.
const smileIDSampleHttpCatalogueSource: UseSmileIDSampleCatalogueSource = {
  supportedIdTypes: (environment) =>
    bodyOf(`${smileIDSampleEnvironmentBaseUrl(environment)}v3/services/supported_id_types`),
  supportedDocuments: (environment, locale) =>
    bodyOf(
      `${smileIDSampleEnvironmentBaseUrl(environment)}v3/services/supported_documents?continent=${CONTINENT}&locale=${encodeURIComponent(locale)}`,
    ),
};

const sourceFor = (mode: UseSmileIDSampleCatalogueMode): UseSmileIDSampleCatalogueSource => {
  switch (mode) {
    case 'live':
      return smileIDSampleHttpCatalogueSource;
    case 'fixture':
      return smileIDSampleFixtureCatalogueSource(fixture);
    case 'unreachable':
      return smileIDSampleUnreachableCatalogueSource;
  }
};

const stores = new Map<UseSmileIDSampleCatalogueMode, UseSmileIDSampleCatalogueStore>();

/// The ID form's lists for the current run, from the source the `catalogue` launch argument names.
export const smileIDSampleCatalogueStore = (mode: UseSmileIDSampleCatalogueMode): UseSmileIDSampleCatalogueStore => {
  let store = stores.get(mode);
  if (store === undefined) {
    store = createSmileIDSampleCatalogueStore(sourceFor(mode));
    stores.set(mode, store);
  }
  return store;
};

/// Where the catalogue asks: the session's environment, as status refresh chooses it.
export const smileIDSampleCatalogueEnvironment = (
  live: UseSmileIDSampleTokenSession | null,
): UseSmileIDSampleEnvironment => (live?.environment === 'production' ? 'production' : 'sandbox');

/// The API translates document and country names; an unsupported locale comes back in English.
export const smileIDSampleCatalogueLocale = (): string => Intl.DateTimeFormat().resolvedOptions().locale;
