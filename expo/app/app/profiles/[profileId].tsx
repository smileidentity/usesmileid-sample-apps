import {
  ProfileConfigScreen,
  smileIDSampleCallbackOverrideCaption,
  smileIDSampleEditorDefaults,
  smileIDSampleUserFieldWrite,
  useSmileIDSampleProfileStore,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleProfileEdit,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';
import { useState } from 'react';

import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';

export default function ProfileConfig() {
  const back = useSmileIDSampleBack('/profiles');
  const { profileId } = useLocalSearchParams<{ profileId: string }>();
  const profile = useSmileIDSampleProfileStore((state) =>
    state.items.find((item) => item.id === profileId),
  );
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const setDefaults = useSmileIDSampleProfileStore((state) => state.setDefaults);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);
  const [edit, setEdit] = useState<UseSmileIDSampleProfileEdit | null>(null);
  /// Keyed by profile like `edit`, so an unsaved URL never carries over to another profile's page.
  const [callbackEdit, setCallbackEdit] = useState<{ profileId: string; value: string } | null>(null);
  const live = useSmileIDSampleSessionStore((state) => state.live);
  const editedCallbackUrl = callbackEdit?.profileId === profileId ? callbackEdit.value : undefined;
  const defaults = smileIDSampleEditorDefaults(edit, profileId, profile?.defaults);

  return (
    <ProfileConfigScreen
      state={{
        organisation: profile?.organisation ?? profileId ?? '',
        defaults,
        isActive: profileId === activeId,
        callbackUrl: editedCallbackUrl ?? profile?.callbackUrl ?? '',
        callbackOverride: live === null ? null : smileIDSampleCallbackOverrideCaption(live),
      }}
      onFieldChange={(field, value) => {
        if (profileId === undefined) return;
        setEdit({ profileId, details: smileIDSampleUserFieldWrite(field, defaults, value) });
      }}
      onCallbackUrlChange={(value) => {
        if (profileId !== undefined) setCallbackEdit({ profileId, value });
      }}
      onBack={() => back()}
      onSave={() => {
        // A profile this build has no row for would otherwise save the fallback over nothing.
        if (profileId === undefined || profile === undefined) return;
        // The CTA reads "Make this profile active", so it has to do both.
        setDefaults(profileId, defaults, editedCallbackUrl?.trim());
        setActive(profileId);
        back();
      }}
    />
  );
}
