import { create, type StoreApi, type UseBoundStore } from 'zustand';

import type { UseSmileIDSampleCatalogueSource } from './use-smile-id-sample-catalogue-source';
import type { UseSmileIDSampleEnvironment } from '../model/use-smile-id-sample-result';
import {
  smileIDSampleCatalogueCountries,
  smileIDSampleCatalogueDocuments,
  smileIDSampleCatalogueIdTypes,
  smileIDSampleDecodeDocuments,
  smileIDSampleDecodeIdTypes,
  type UseSmileIDSampleApiCountryDocuments,
  type UseSmileIDSampleApiIdType,
  type UseSmileIDSampleCatalogue,
} from '../state/use-smile-id-sample-catalogue';
import type {
  UseSmileIDSampleCatalogueFamily,
  UseSmileIDSampleCountry,
  UseSmileIDSampleDocument,
  UseSmileIDSampleKycIdType,
} from '../state/use-smile-id-sample-id-details';

/// How long a list may take before it is a failure.
const TIMEOUT_MS = 10_000;

const LOADING = { kind: 'loading' } as const;

type Run = {
  readonly environment: UseSmileIDSampleEnvironment;
  readonly locale: string;
};

type State = {
  readonly run: Run | null;
  readonly idTypes: UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType>;
  readonly documents: UseSmileIDSampleCatalogue<UseSmileIDSampleApiCountryDocuments>;
};

type Actions = {
  /// A product tap: a new run always asks the server again, so a list changed on the server shows up.
  begin: (environment: UseSmileIDSampleEnvironment, locale: string) => void;
  /// The form itself: a deep link can land there without the product tap, so start only if nothing has.
  ensure: (environment: UseSmileIDSampleEnvironment, locale: string) => void;
  /// Asks again for whichever list failed.
  retry: () => void;
  /// Leaving the form: anything in flight is dropped and the next run starts clean.
  stop: () => void;
};

/// The ID form's lists for one run: fetched ahead, held in memory only.
export type UseSmileIDSampleCatalogueStore = UseBoundStore<StoreApi<State & Actions>>;

/// One store per app, over the source the `catalogue` launch argument picked.
export const createSmileIDSampleCatalogueStore = (
  source: UseSmileIDSampleCatalogueSource,
  timeoutMs: number = TIMEOUT_MS,
): UseSmileIDSampleCatalogueStore => {
  let generation = 0;

  const load = async <T>(
    fetch: () => Promise<string>,
    decode: (body: string) => T[] | null,
  ): Promise<UseSmileIDSampleCatalogue<T>> => {
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      const timeout = new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error(`Timed out after ${timeoutMs} ms`)), timeoutMs);
      });
      const items = decode(await Promise.race([fetch(), timeout]));
      return items === null ? { kind: 'failed', reason: 'Unreadable response' } : { kind: 'ready', items };
    } catch (error) {
      return {
        kind: 'failed',
        reason: error instanceof Error ? error.message : String(error),
      };
    } finally {
      clearTimeout(timer);
    }
  };

  return create<State & Actions>((set, get) => {
    const fetchIdTypes = () => {
      const run = get().run;
      if (run === null) return;
      const at = generation;
      set({ idTypes: LOADING });
      void load(() => source.supportedIdTypes(run.environment), smileIDSampleDecodeIdTypes).then((idTypes) => {
        if (at === generation) set({ idTypes });
      });
    };
    const fetchDocuments = () => {
      const run = get().run;
      if (run === null) return;
      const at = generation;
      set({ documents: LOADING });
      void load(() => source.supportedDocuments(run.environment, run.locale), smileIDSampleDecodeDocuments).then(
        (documents) => {
          if (at === generation) set({ documents });
        },
      );
    };
    return {
      run: null,
      idTypes: LOADING,
      documents: LOADING,
      begin: (environment, locale) => {
        get().stop();
        set({ run: { environment, locale } });
        fetchIdTypes();
        fetchDocuments();
      },
      ensure: (environment, locale) => {
        const run = get().run;
        if (run?.environment !== environment || run.locale !== locale) get().begin(environment, locale);
      },
      retry: () => {
        if (get().idTypes.kind === 'failed') fetchIdTypes();
        if (get().documents.kind === 'failed') fetchDocuments();
      },
      stop: () => {
        generation++;
        set({ run: null, idTypes: LOADING, documents: LOADING });
      },
    };
  });
};

const settled = <T>(items: readonly T[]): UseSmileIDSampleCatalogue<T> =>
  items.length === 0 ? { kind: 'empty' } : { kind: 'ready', items };

/// The same failure or wait, retyped for the list derived from it.
const notReady = <T>(
  list: Exclude<UseSmileIDSampleCatalogue<unknown>, { kind: 'ready' }>,
): UseSmileIDSampleCatalogue<T> => list;

/// The countries `family` offers; the document products never wait on `supported_id_types`.
export const smileIDSampleCatalogueCountriesOf = (
  state: State,
  family: UseSmileIDSampleCatalogueFamily,
): UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> => {
  const idTypes: UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> =
    family === 'kyc' ? state.idTypes : { kind: 'ready', items: [] };
  if (state.documents.kind === 'failed') return state.documents;
  if (idTypes.kind === 'failed') return idTypes;
  if (state.documents.kind !== 'ready' || idTypes.kind !== 'ready') return LOADING;
  return settled(smileIDSampleCatalogueCountries({ idTypes: idTypes.items, documents: state.documents.items }, family));
};

/// The ID types `country` offers.
export const smileIDSampleCatalogueIdTypesOf = (
  state: State,
  country: string,
): UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType> =>
  state.idTypes.kind === 'ready'
    ? settled(smileIDSampleCatalogueIdTypes(state.idTypes.items, country))
    : notReady(state.idTypes);

/// The documents `country` offers.
export const smileIDSampleCatalogueDocumentsOf = (
  state: State,
  country: string,
): UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> =>
  state.documents.kind === 'ready'
    ? settled(smileIDSampleCatalogueDocuments(state.documents.items, country))
    : notReady(state.documents);
