import { IdTypePickerSheet, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { useSmileIDSampleBack } from '../../../../src/use-smile-id-sample-back';
import { useState } from 'react';

export default function IdTypePicker() {
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const back = useSmileIDSampleBack(`/flow/${productId}/id-details`);
  const [query, setQuery] = useState('');
  const country = useSmileIDSampleFormsStore((state) => state.idDetails.country);
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.idType);
  const setIdType = useSmileIDSampleFormsStore((state) => state.setIdType);

  return (
    <IdTypePickerSheet
      country={country}
      selected={selected}
      query={query}
      onQueryChange={setQuery}
      onSelect={(idType) => {
        setIdType(idType);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
