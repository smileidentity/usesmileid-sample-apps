import {
  createSmileIDSampleCatalogueStore,
  smileIDSampleCatalogueCountriesOf,
  smileIDSampleCatalogueDocumentsOf,
  smileIDSampleCatalogueIdTypesOf,
} from '../src/data/use-smile-id-sample-catalogue-store';
import {
  smileIDSampleFixtureCatalogueSource,
  type UseSmileIDSampleCatalogueSource,
} from '../src/data/use-smile-id-sample-catalogue-source';
import { catalogueFixture, fixtureIdTypes } from './catalogue-fixtures';

/// The fixture, counting calls, with a switchable failure and a hang released by hand.
const counting = (options: { failIdTypes?: boolean; hang?: boolean } = {}) => {
  const fixture = smileIDSampleFixtureCatalogueSource(catalogueFixture);
  let release: () => void = () => {};
  const released = new Promise<void>((resolve) => {
    release = resolve;
  });
  const calls = {
    idTypes: 0,
    documents: 0,
    failIdTypes: options.failIdTypes ?? false,
    locales: [] as string[],
  };
  const source: UseSmileIDSampleCatalogueSource = {
    supportedIdTypes: async (environment) => {
      calls.idTypes++;
      if (calls.failIdTypes) throw new Error('offline');
      if (options.hang) await released;
      return fixture.supportedIdTypes(environment);
    },
    supportedDocuments: async (environment, locale) => {
      calls.documents++;
      calls.locales.push(locale);
      if (options.hang) await released;
      return fixture.supportedDocuments(environment, locale);
    },
  };
  return { source, calls, release: () => release() };
};

const settle = () => jest.advanceTimersByTimeAsync(0);

/// The store fetches ahead, fails whole lists, retries only what failed and drops a run it left.
describe('the catalogue store', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  it('fetches both lists on a product tap, and the rules apply', async () => {
    const { source, calls } = counting();
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().begin('sandbox', 'en-GB');
    expect(smileIDSampleCatalogueCountriesOf(store.getState(), 'kyc').kind).toBe('loading');
    await settle();

    expect(calls).toMatchObject({
      idTypes: 1,
      documents: 1,
      locales: ['en-GB'],
    });
    const kenya = smileIDSampleCatalogueIdTypesOf(store.getState(), 'KE');
    expect(kenya.kind === 'ready' && kenya.items.map((it) => it.id)).toEqual(fixtureIdTypes('KE').map((it) => it.id));
  });

  it('does not ask again when the form enters the same run, and does for a deep link with none', async () => {
    const { source, calls } = counting();
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().ensure('sandbox', 'en-GB');
    await settle();
    store.getState().ensure('sandbox', 'en-GB');
    await settle();
    expect(calls.idTypes).toBe(1);
  });

  it('fails a list whole, and Retry asks only for that one', async () => {
    const { source, calls } = counting({ failIdTypes: true });
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().begin('sandbox', 'en-GB');
    await settle();

    expect(smileIDSampleCatalogueIdTypesOf(store.getState(), 'KE').kind).toBe('failed');
    expect(smileIDSampleCatalogueCountriesOf(store.getState(), 'kyc').kind).toBe('failed');
    // The document products never read supported_id_types.
    expect(smileIDSampleCatalogueCountriesOf(store.getState(), 'document').kind).toBe('ready');

    calls.failIdTypes = false;
    store.getState().retry();
    await settle();
    expect(calls).toMatchObject({ idTypes: 2, documents: 1 });
    expect(smileIDSampleCatalogueIdTypesOf(store.getState(), 'KE').kind).toBe('ready');
  });

  it('fails a list that never answers after ten seconds', async () => {
    const { source } = counting({ hang: true });
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().begin('sandbox', 'en-GB');
    await jest.advanceTimersByTimeAsync(9_000);
    expect(smileIDSampleCatalogueDocumentsOf(store.getState(), 'KE').kind).toBe('loading');
    await jest.advanceTimersByTimeAsync(2_000);
    expect(smileIDSampleCatalogueDocumentsOf(store.getState(), 'KE').kind).toBe('failed');
  });

  it('drops an answer that arrives after stop', async () => {
    const { source, release } = counting({ hang: true });
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().begin('sandbox', 'en-GB');
    store.getState().stop();
    release();
    await settle();
    expect(smileIDSampleCatalogueDocumentsOf(store.getState(), 'KE').kind).toBe('loading');
  });

  it('asks the server again on every new run', async () => {
    const { source, calls } = counting();
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().begin('sandbox', 'en-GB');
    await settle();
    store.getState().begin('sandbox', 'en-GB');
    await settle();
    expect(calls.documents).toBe(2);
  });
});
