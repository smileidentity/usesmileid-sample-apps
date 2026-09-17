import {
  NewProfileSheet,
  smileIDSampleNewProfileDraftEmpty,
  useSmileIDSampleProfileStore,
  type UseSmileIDSampleNewProfileDraft,
} from '@smileid/sample-ui';

import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';
import { useState } from 'react';

export default function NewProfile() {
  const back = useSmileIDSampleBack('/profiles');
  const add = useSmileIDSampleProfileStore((state) => state.add);
  // Mounted only while the route is, so its five fields start empty each time.
  const [draft, setDraft] = useState<UseSmileIDSampleNewProfileDraft>(
    smileIDSampleNewProfileDraftEmpty,
  );

  return (
    <NewProfileSheet
      draft={draft}
      onDraftChange={setDraft}
      onSave={() => {
        // The person is the two required names; all four seed the details its jobs start from.
        add(draft.name, `${draft.firstName} ${draft.lastName}`.trim(), {
          firstName: draft.firstName,
          lastName: draft.lastName,
          email: draft.email,
          phone: draft.phone,
        });
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
