import { CountryPickerSheet, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';
import { useState } from 'react';

export default function CountryPicker() {
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const [query, setQuery] = useState('');
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.country);
  const setCountry = useSmileIDSampleFormsStore((state) => state.setCountry);

  return (
    <CountryPickerSheet
      selected={selected}
      query={query}
      onQueryChange={setQuery}
      onSelect={(country) => {
        setCountry(country);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
