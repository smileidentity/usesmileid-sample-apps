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
  // From the switch sheet the profile is active at once, and from the form it starts from the typing.
  const { activate, fromForm } = useLocalSearchParams<{ activate?: string; fromForm?: string }>();
  // Mounted only while the route is, so its five fields start empty each time unless the form's typing seeds them.
  const [draft, setDraft] = useState<UseSmileIDSampleNewProfileDraft>(() => {
    if (fromForm !== '1') return smileIDSampleNewProfileDraftEmpty;
    const forms = useSmileIDSampleFormsStore.getState();
    return { name: forms.organisation, ...forms.userDetails };
  });

  return (
    <NewProfileSheet
      draft={draft}
      onDraftChange={setDraft}
      onSave={() => {
        // All four seed the details its jobs start from; the two names are also who the profile names.
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
