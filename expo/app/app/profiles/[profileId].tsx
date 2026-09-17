import {
  ProfileConfigScreen,
  smileIDSampleUserFieldWrite,
  smileIDSampleUserDetailsDefaults,
  useSmileIDSampleProfileStore,
  type UseSmileIDSampleUserDetails,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';
import { useState } from 'react';

import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';

/// What the partner has typed, and which profile they typed it into.
type Edit = { readonly profileId: string; readonly details: UseSmileIDSampleUserDetails };

export default function ProfileConfig() {
  const back = useSmileIDSampleBack('/profiles');
  const { profileId } = useLocalSearchParams<{ profileId: string }>();
  const profile = useSmileIDSampleProfileStore((state) =>
    state.items.find((item) => item.id === profileId),
  );
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const setDefaults = useSmileIDSampleProfileStore((state) => state.setDefaults);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);
  const [edit, setEdit] = useState<Edit | null>(null);

  // The store until the partner types, so a profile arriving after the first render is shown rather
  // than an empty form that would save its emptiness over the stored defaults. Keyed by id, because
  // a second profile opened on the same route would otherwise inherit the first one's edit.
  const edited = edit !== null && edit.profileId === profileId ? edit.details : null;
  const defaults = edited ?? profile?.defaults ?? smileIDSampleUserDetailsDefaults;

  return (
    <ProfileConfigScreen
      state={{
        organisation: profile?.organisation ?? profileId ?? '',
        defaults,
        isActive: profileId === activeId,
      }}
      onFieldChange={(field, value) => {
        if (profileId === undefined) return;
        setEdit({ profileId, details: smileIDSampleUserFieldWrite(field, defaults, value) });
      }}
      onBack={() => back()}
      onSave={() => {
        // A profile this build has no row for would otherwise save the fallback over nothing.
        if (profileId === undefined || profile === undefined) return;
        // The CTA reads "Make this profile active", so it has to do both.
        setDefaults(profileId, defaults);
        setActive(profileId);
        back();
      }}
    />
  );
}
