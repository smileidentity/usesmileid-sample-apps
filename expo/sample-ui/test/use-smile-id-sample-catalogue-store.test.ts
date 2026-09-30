import {
  createSmileIDSampleCatalogueStore,
  smileIDSampleCatalogueCountriesOf,
  smileIDSampleCatalogueDocumentsOf,
  smileIDSampleCatalogueIdTypesOf,
} from '../src/data/use-smile-id-sample-catalogue-store';
import {
  smileIDSampleFixtureCatalogueSource,
  smileIDSampleSessionAwareCatalogueSource,
  smileIDSampleUnreachableCatalogueSource,
  UseSmileIDSampleCatalogueHttpError,
  type UseSmileIDSampleCatalogueSource,
} from '../src/data/use-smile-id-sample-catalogue-source';
import {
  smileIDSampleCatalogueAdvice,
  smileIDSampleCatalogueDefaultAdvice,
} from '../src/state/use-smile-id-sample-catalogue';
import type { UseSmileIDSampleTokenSession } from '../src/state/use-smile-id-sample-token-session';
import { catalogueFixture, fixtureIdTypes } from './catalogue-fixtures';

const EDV = 'enhancedDocumentVerification';

const session = (id: string): UseSmileIDSampleTokenSession => ({
  id,
  token: `token-${id}`,
  issuedAtMillis: 0,
  expiresAtMillis: 1,
  bindings: {},
  partnerId: null,
  environment: 'sandbox',
});

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
    config: 0,
    lastToken: null as string | null,
    refusing: null as number | null,
    offline: false,
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
    servicesConfig: async (environment, token, locale) => {
      calls.config++;
      calls.lastToken = token;
      if (calls.refusing !== null) throw new UseSmileIDSampleCatalogueHttpError(calls.refusing);
      if (calls.offline) throw new Error('offline');
      return fixture.servicesConfig(environment, token, locale);
    },
  };
  return { source, calls, release: () => release() };
};

const settle = () => jest.advanceTimersByTimeAsync(0);

/// The store fetches ahead, fails whole lists, retries only what failed and drops a run it left.
describe('the catalogue store', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  it('offers only what the partner enabled on Enhanced Document Verification', async () => {
    const { source, calls } = counting();
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().begin('sandbox', 'en-GB');
    store.getState().ensureEnabled('sandbox', 'en-GB', session('a'));
    await settle();

    expect(calls.lastToken).toBe('token-a');
    const enabled = smileIDSampleCatalogueCountriesOf(store.getState(), 'document', EDV);
    expect(enabled.kind === 'ready' && enabled.items.map((it) => it.code)).toEqual(['KE', 'NG']);
    const all = smileIDSampleCatalogueCountriesOf(store.getState(), 'document');
    expect(all.kind === 'ready' && all.items.map((it) => it.code)).toEqual(['GH', 'KE', 'NG', 'ZA']);
    const kenya = smileIDSampleCatalogueDocumentsOf(store.getState(), 'KE', EDV);
    expect(kenya.kind === 'ready' && kenya.items.map((it) => it.code)).toEqual(['IDENTITY_CARD', 'PASSPORT']);
  });

  it("keeps the partner's list per session, and asks again on a relink", async () => {
    const { source, calls } = counting();
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().ensureEnabled('sandbox', 'en-GB', session('a'));
    await settle();
    store.getState().stop();
    store.getState().begin('sandbox', 'en-GB');
    store.getState().ensureEnabled('sandbox', 'en-GB', session('a'));
    await settle();
    expect(calls.config).toBe(1);

    store.getState().ensureEnabled('sandbox', 'en-GB', session('b'));
    await settle();
    expect(calls.config).toBe(2);
    expect(calls.lastToken).toBe('token-b');
  });

  it.each([401, 403])('names a %i and asks again on retry', async (status) => {
    const { source, calls } = counting();
    calls.refusing = status;
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().begin('production', 'en-GB');
    store.getState().ensureEnabled('production', 'en-GB', session('a'));
    await settle();
    const failed = smileIDSampleCatalogueCountriesOf(store.getState(), 'document', EDV);
    expect(failed.kind === 'failed' && failed.advice).toBe(smileIDSampleCatalogueAdvice(status));

    calls.refusing = null;
    store.getState().retry();
    await settle();
    expect(smileIDSampleCatalogueCountriesOf(store.getState(), 'document', EDV).kind).toBe('ready');
  });

  it("gives no network on the partner's list the default line", async () => {
    const { source, calls } = counting();
    calls.offline = true;
    const store = createSmileIDSampleCatalogueStore(source);
    store.getState().ensureEnabled('sandbox', 'en-GB', session('a'));
    await settle();
    const failed = store.getState().enabled;
    expect(failed.kind).toBe('failed');
    expect(failed.kind === 'failed' ? (failed.advice ?? smileIDSampleCatalogueDefaultAdvice) : null).toBe(
      smileIDSampleCatalogueDefaultAdvice,
    );
  });

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

const token = (header: string) =>
  [header, '{}', 'not-a-signature'].map((part) => Buffer.from(part, 'utf8').toString('base64url')).join('.');

/// A simulated session's unsigned token reads the fixture; a signed one asks the server.
describe('the session-aware source', () => {
  const fixture = smileIDSampleFixtureCatalogueSource(catalogueFixture);
  const source = smileIDSampleSessionAwareCatalogueSource(smileIDSampleUnreachableCatalogueSource, fixture);

  it('reads the fixture for an unsigned token', async () => {
    const unsigned = token('{"alg":"none","typ":"JWT"}');
    await expect(source.servicesConfig('sandbox', unsigned, 'en-GB')).resolves.toBe(
      await fixture.servicesConfig('sandbox', unsigned, 'en-GB'),
    );
  });

  it('refuses an empty token without asking the server', async () => {
    await expect(source.servicesConfig('sandbox', '', 'en-GB')).rejects.toMatchObject({ status: 401 });
  });

  it('asks the server for a signed token', async () => {
    await expect(source.servicesConfig('sandbox', token('{"alg":"HS256","typ":"JWT"}'), 'en-GB')).rejects.toThrow();
  });
});
