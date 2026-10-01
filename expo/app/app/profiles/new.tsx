import {
  NewProfileSheet,
  smileIDSampleNewProfileDraftEmpty,
  useSmileIDSampleFormsStore,
  useSmileIDSampleProfileStore,
  type UseSmileIDSampleNewProfileDraft,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';
import { useState } from 'react';

export default function NewProfile() {
  const back = useSmileIDSampleBack('/profiles');
  const add = useSmileIDSampleProfileStore((state) => state.add);
  const fillFrom = useSmileIDSampleFormsStore((state) => state.fillFrom);
  const { activate } = useLocalSearchParams<{ activate?: string }>();
  const [draft, setDraft] = useState<UseSmileIDSampleNewProfileDraft>(smileIDSampleNewProfileDraftEmpty);

  return (
    <NewProfileSheet
      draft={draft}
      onDraftChange={setDraft}
      onSave={() => {
        const id = add(
          draft.name,
          { firstName: draft.firstName, lastName: draft.lastName, email: draft.email, phone: draft.phone },
          activate === '1',
        );
        const created = useSmileIDSampleProfileStore.getState().items.find((item) => item.id === id);
        if (activate === '1' && created !== undefined) fillFrom(created);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
