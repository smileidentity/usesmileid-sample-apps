import {
  KycIdFormScreen,
  smileIDSampleCatalogueCountriesOf,
  smileIDSampleCatalogueDocumentsOf,
  smileIDSampleSettledItems,
  smileIDSampleCatalogueFamily,
  smileIDSampleCatalogueIdTypesOf,
  smileIDSampleLiveSession,
  smileIDSampleProductFrom,
  useSmileIDSampleFormsStore,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleCatalogueFamily,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useMemo } from 'react';

import {
  smileIDSampleCatalogueEnvironment,
  smileIDSampleCatalogueLocale,
  smileIDSampleCatalogueStore,
  smileIDSampleEnsureEnabled,
} from '../../../../src/catalogue/use-smile-id-sample-catalogue';
import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';
import { useLaunchArgs } from '../../../../src/use-smile-id-sample-launch';

const enabledListsOf = (
  catalogue: Parameters<typeof smileIDSampleCatalogueCountriesOf>[0],
  family: UseSmileIDSampleCatalogueFamily,
  country: string | undefined,
) => ({
  countries: smileIDSampleSettledItems(smileIDSampleCatalogueCountriesOf(catalogue, family, 'enhancedDocumentVerification')),
  documents:
    country === undefined
      ? null
      : smileIDSampleSettledItems(smileIDSampleCatalogueDocumentsOf(catalogue, country, 'enhancedDocumentVerification')),
});

export default function IdDetailsForm() {
  const router = useRouter();
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/details`);
  const product = smileIDSampleProductFrom(productId);
  const family = (product === null ? null : smileIDSampleCatalogueFamily(product)) ?? 'kyc';
  const details = useSmileIDSampleFormsStore((state) => state.idDetails);
  const setIdNumber = useSmileIDSampleFormsStore((state) => state.setIdNumber);
  const keepDocumentListedOn = useSmileIDSampleFormsStore((state) => state.keepDocumentListedOn);
  const store = smileIDSampleCatalogueStore(useLaunchArgs().catalogue);
  const catalogue = store();

  // A deep link lands here without the product tap that fetches ahead, so the form starts it; leaving drops it.
  useEffect(() => {
    const sessions = useSmileIDSampleSessionStore.getState();
    store
      .getState()
      .ensure(
        smileIDSampleCatalogueEnvironment(smileIDSampleLiveSession(sessions, sessions.nowMillis)),
        smileIDSampleCatalogueLocale(),
      );
    return () => store.getState().stop();
  }, [store]);

  const liveSessionId = useSmileIDSampleSessionStore(
    (state) => smileIDSampleLiveSession(state, state.nowMillis)?.id ?? null,
  );
  useEffect(() => {
    const sessions = useSmileIDSampleSessionStore.getState();
    smileIDSampleEnsureEnabled(store, productId, smileIDSampleLiveSession(sessions, sessions.nowMillis));
  }, [store, productId, liveSessionId]);

  // A link can open this form holding a row the product does not list.
  useEffect(() => {
    if (productId !== undefined) keepDocumentListedOn(productId);
  }, [productId, keepDocumentListedOn]);

  const keepOnlyEnabled = useSmileIDSampleFormsStore((state) => state.keepOnlyEnabled);
  const pickedCountry = details.country?.code;
  const enabledLists = useMemo(
    () => (productId === 'enhancedDocumentVerification' ? enabledListsOf(catalogue, family, pickedCountry) : null),
    [catalogue, family, productId, pickedCountry],
  );
  useEffect(() => {
    if (enabledLists === null) return;
    // Read again: the effect above may have just reset a previous session's list.
    const fresh = enabledListsOf(store.getState(), family, useSmileIDSampleFormsStore.getState().idDetails.country?.code);
    keepOnlyEnabled(fresh.countries, fresh.documents);
  }, [enabledLists, store, family, keepOnlyEnabled]);

  const country = details.country?.code;
  const countryList =
    country === undefined
      ? null
      : family === 'kyc'
        ? smileIDSampleCatalogueIdTypesOf(catalogue, country)
        : smileIDSampleCatalogueDocumentsOf(catalogue, country, productId);

  return (
    <KycIdFormScreen
      state={{
        productLabel: product?.label ?? productId ?? '',
        family,
        details,
        countryListLoading: countryList?.kind === 'loading',
      }}
      onCountryPress={() => router.push(`/flow/${productId}/id-details/country`)}
      onIdTypePress={() => router.push(`/flow/${productId}/id-details/id-type`)}
      onDocumentPress={() => router.push(`/flow/${productId}/id-details/document`)}
      onCaptureAsPress={() => router.push(`/flow/${productId}/id-details/capture-as`)}
      onIdNumberChange={setIdNumber}
      onBack={() => back()}
      onContinue={() => router.push(`/flow/${productId}/run`)}
      onTokenPress={() => router.push('/token/scan')}
    />
  );
}
