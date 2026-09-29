import {
  KycIdFormScreen,
  smileIDSampleCatalogueDocumentsOf,
  smileIDSampleCatalogueFamily,
  smileIDSampleCatalogueIdTypesOf,
  smileIDSampleLiveSession,
  smileIDSampleProductFrom,
  useSmileIDSampleFormsStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleSettingsStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect } from 'react';

import {
  smileIDSampleCatalogueEnvironment,
  smileIDSampleCatalogueLocale,
  smileIDSampleCatalogueStore,
} from '../../../../src/catalogue/use-smile-id-sample-catalogue';
import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';
import { useLaunchArgs } from '../../../../src/use-smile-id-sample-launch';

export default function IdDetailsForm() {
  const router = useRouter();
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/details`);
  const product = smileIDSampleProductFrom(productId);
  const family = (product === null ? null : smileIDSampleCatalogueFamily(product)) ?? 'kyc';
  const details = useSmileIDSampleFormsStore((state) => state.idDetails);
  const setIdNumber = useSmileIDSampleFormsStore((state) => state.setIdNumber);
  const captureBothSides = useSmileIDSampleSettingsStore((state) => state.settings.captureBothSides);
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
        captureBothSides,
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
