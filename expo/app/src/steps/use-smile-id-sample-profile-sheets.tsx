import {
  NewProfileSheet,
  ProfileSwitchSheet,
  smileIDSampleNewProfileDraftEmpty,
  useSmileIDSampleFormsStore,
  useSmileIDSampleProfileStore,
  type UseSmileIDSampleNewProfileDraft,
} from '@smileid/sample-ui';
import { useState } from 'react';

import type { UseSmileIDSampleStepScope } from '../navigation/use-smile-id-sample-navigation';

/// The switch sheet over Products or the form; a pick refills the form, and "New profile" swaps in the new-profile form, active at once.
export const UseSmileIDSampleProfileSwitchStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const [creating, setCreating] = useState(false);
  const fillFrom = useSmileIDSampleFormsStore((state) => state.fillFrom);
  const profiles = useSmileIDSampleProfileStore((state) => state.items);
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);

  if (creating) return <UseSmileIDSampleNewProfileForm activate onDone={() => scope.navigator.back()} />;

  return (
    <ProfileSwitchSheet
      profiles={profiles}
      activeId={activeId}
      onSelect={(profile) => {
        setActive(profile.id);
        fillFrom(profile);
        scope.navigator.back();
      }}
      onCreate={() => setCreating(true)}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The new-profile sheet over the profiles list.
export const UseSmileIDSampleNewProfileStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => (
  <UseSmileIDSampleNewProfileForm activate={false} onDone={() => scope.navigator.back()} />
);

/// The new-profile form, which closes with `onDone` once it has made a profile, active and filling the form when `activate`.
const UseSmileIDSampleNewProfileForm = ({ activate, onDone }: { activate: boolean; onDone: () => void }) => {
  const add = useSmileIDSampleProfileStore((state) => state.add);
  const fillFrom = useSmileIDSampleFormsStore((state) => state.fillFrom);
  const [draft, setDraft] = useState<UseSmileIDSampleNewProfileDraft>(smileIDSampleNewProfileDraftEmpty);

  return (
    <NewProfileSheet
      draft={draft}
      onDraftChange={setDraft}
      onSave={() => {
        const id = add(
          draft.name,
          { firstName: draft.firstName, lastName: draft.lastName, email: draft.email, phone: draft.phone },
          activate,
        );
        const created = useSmileIDSampleProfileStore.getState().items.find((item) => item.id === id);
        if (activate && created !== undefined) fillFrom(created);
        onDone();
      }}
      onDismiss={onDone}
    />
  );
};
