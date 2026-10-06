import {
  createSmileIDSampleCatalogueStore,
  smileIDSampleEnhancedDocumentVerificationKey,
  smileIDSampleEnvironmentBaseUrl,
  smileIDSampleFixtureCatalogueSource,
  smileIDSampleSessionAwareCatalogueSource,
  smileIDSampleUnreachableCatalogueSource,
  UseSmileIDSampleCatalogueHttpError,
  type UseSmileIDSampleCatalogueMode,
  type UseSmileIDSampleCatalogueSource,
  type UseSmileIDSampleCatalogueStore,
  type UseSmileIDSampleEnvironment,
  type UseSmileIDSampleTokenSession,
} from '@smileid/sample-ui';

// A copy of spec/catalogue-fixture.json: Metro cannot reach spec/, and verify.sh fails if the copy drifts.
import { getLocales } from 'expo-localization';

import fixture from '../../assets/catalogue-fixture.json';
import { smileIDSamplePinnedLanguage } from '../use-smile-id-sample-pinned-language';

// The store's own timeout, so a request it gives up on is torn down rather than left open.
const REQUEST_TIMEOUT_MS = 10_000;

const bodyOf = async (url: string, token?: string): Promise<string> => {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      headers: token === undefined ? undefined : { 'SmileID-Token': token },
    });
    if (!response.ok) throw new UseSmileIDSampleCatalogueHttpError(response.status);
    return await response.text();
  } finally {
    clearTimeout(timer);
  }
};

/// The two unauthenticated catalogue endpoints, and the partner's own configuration under its token.
const smileIDSampleHttpCatalogueSource: UseSmileIDSampleCatalogueSource = {
  supportedIdTypes: (environment) =>
    bodyOf(`${smileIDSampleEnvironmentBaseUrl(environment)}v3/services/supported_id_types`),
  supportedDocuments: (environment, locale) =>
    bodyOf(
      `${smileIDSampleEnvironmentBaseUrl(environment)}v3/services/supported_documents?locale=${encodeURIComponent(locale)}`,
    ),
  servicesConfig: (environment, token, locale) =>
    bodyOf(
      `${smileIDSampleEnvironmentBaseUrl(environment)}v3/services/config?product=${smileIDSampleEnhancedDocumentVerificationKey}&locale=${encodeURIComponent(locale)}`,
      token,
    ),
};

const sourceFor = (mode: UseSmileIDSampleCatalogueMode): UseSmileIDSampleCatalogueSource => {
  switch (mode) {
    case 'live':
      return smileIDSampleSessionAwareCatalogueSource(
        smileIDSampleHttpCatalogueSource,
        smileIDSampleFixtureCatalogueSource(fixture),
      );
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
export const smileIDSampleCatalogueLocale = (): string =>
  smileIDSamplePinnedLanguage() ?? getLocales()[0]?.languageTag ?? 'en';

/// Enhanced Document Verification's own list, which `live`'s token decides; any other product has none.
export const smileIDSampleEnsureEnabled = (
  store: UseSmileIDSampleCatalogueStore,
  productId: string | undefined,
  live: UseSmileIDSampleTokenSession | null,
): void => {
  if (productId !== 'enhancedDocumentVerification') return;
  store.getState().ensureEnabled(smileIDSampleCatalogueEnvironment(live), smileIDSampleCatalogueLocale(), live);
};
