import { IdTypePickerSheet, smileIDSampleCatalogueIdTypesOf, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { Redirect, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';

import { smileIDSampleCatalogueStore } from '../../../../src/catalogue/use-smile-id-sample-catalogue';
import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';
import { useLaunchArgs } from '../../../../src/use-smile-id-sample-launch';

export default function IdTypePicker() {
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const [query, setQuery] = useState('');
  const store = smileIDSampleCatalogueStore(useLaunchArgs().catalogue);
  const catalogue = store();
  const country = useSmileIDSampleFormsStore((state) => state.idDetails.country);
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.idType);
  const setIdType = useSmileIDSampleFormsStore((state) => state.setIdType);

  // Its trigger could not open it yet, so neither may a link: refused, not held until later.
  if (country === null) return <Redirect href={`/flow/${productId}/id-details`} />;

  return (
    <IdTypePickerSheet
      country={country}
      catalogue={smileIDSampleCatalogueIdTypesOf(catalogue, country.code)}
      selected={selected}
      query={query}
      onQueryChange={setQuery}
      onSelect={(idType) => {
        setIdType(idType);
        back();
      }}
      onRetry={() => store.getState().retry()}
      onDismiss={() => back()}
    />
  );
}
