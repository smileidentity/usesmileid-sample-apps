import { CountryPickerSheet, useSmileIDSampleFormsStore } from '@smileid/sample-ui';
import { useRouter } from 'expo-router';
import { useState } from 'react';

export default function CountryPicker() {
  const router = useRouter();
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
        router.back();
      }}
      onDismiss={() => router.back()}
    />
  );
}
