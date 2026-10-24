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
  smileIDSampleProductTitle,
  useSmileIDSampleStrings,
} from '@smileid/sample-ui';
import { useEffect, useMemo } from 'react';

import {
  smileIDSampleCatalogueEnvironment,
  smileIDSampleCatalogueLocale,
  smileIDSampleCatalogueStore,
  smileIDSampleEnsureEnabled,
} from '../catalogue/use-smile-id-sample-catalogue';
import {
  smileIDSampleRunProductId,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { useLaunchArgs } from '../use-smile-id-sample-launch';

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

/// The ID-details form, whose pickers open as sheets over it.
export const UseSmileIDSampleIdDetailsStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const strings = useSmileIDSampleStrings();
  const productId = smileIDSampleRunProductId(useSmileIDSampleEngine(), scope.entry);
  const back = () => scope.navigator.back();
  const product = smileIDSampleProductFrom(productId);
  const family = (product === null ? null : smileIDSampleCatalogueFamily(product)) ?? 'kyc';
  const productLabel = product === null ? (productId ?? '') : smileIDSampleProductTitle(product, strings);
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
        productLabel,
        family,
        details,
        countryListLoading: countryList?.kind === 'loading',
      }}
      onCountryPress={() => scope.navigator.go('countryPicker')}
      onIdTypePress={() => scope.navigator.go('idTypePicker')}
      onDocumentPress={() => scope.navigator.go('documentPicker')}
      onCaptureAsPress={() => scope.navigator.go('captureAs')}
      onIdNumberChange={setIdNumber}
      onBack={() => back()}
      onContinue={() => scope.navigator.next()}
      onTokenPress={() => scope.navigator.go('scanToken')}
    />
  );
};
