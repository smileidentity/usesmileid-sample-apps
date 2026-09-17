import { IdTypePickerSheet, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { useRouter } from 'expo-router';
import { useState } from 'react';

export default function IdTypePicker() {
  const router = useRouter();
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
        router.back();
      }}
      onDismiss={() => router.back()}
    />
  );
}
