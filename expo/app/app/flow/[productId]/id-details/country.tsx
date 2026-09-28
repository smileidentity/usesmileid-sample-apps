import {
  CountryPickerSheet,
  smileIDSampleCatalogueCountriesOf,
  smileIDSampleCatalogueFamily,
  smileIDSampleProductFrom,
  useSmileIDSampleFormsStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';
import { useState } from 'react';

import { smileIDSampleCatalogueStore } from '../../../../src/catalogue/use-smile-id-sample-catalogue';
import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';
import { useLaunchArgs } from '../../../../src/use-smile-id-sample-launch';

export default function CountryPicker() {
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const [query, setQuery] = useState('');
  const product = smileIDSampleProductFrom(productId);
  const family = (product === null ? null : smileIDSampleCatalogueFamily(product)) ?? 'kyc';
  const store = smileIDSampleCatalogueStore(useLaunchArgs().catalogue);
  const catalogue = store();
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.country);
  const setCountry = useSmileIDSampleFormsStore((state) => state.setCountry);

  return (
    <CountryPickerSheet
      catalogue={smileIDSampleCatalogueCountriesOf(catalogue, family)}
      selected={selected}
      query={query}
      onQueryChange={setQuery}
      onSelect={(country) => {
        setCountry(country);
        back();
      }}
      onRetry={() => store.getState().retry()}
      onDismiss={() => back()}
    />
  );
}
