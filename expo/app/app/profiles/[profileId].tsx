import {
  ProfileConfigScreen,
  smileIDSampleCallbackOverrideCaption,
  smileIDSampleEditorDefaults,
  smileIDSampleProfileTitle,
  smileIDSampleUserFieldWrite,
  useSmileIDSampleProfileStore,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleProfileEdit,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';
import { useEffect, useRef, useState } from 'react';

import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';

export default function ProfileConfig() {
  const back = useSmileIDSampleBack('/profiles');
  const { profileId } = useLocalSearchParams<{ profileId: string }>();
  const profile = useSmileIDSampleProfileStore((state) =>
    state.items.find((item) => item.id === profileId),
  );
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const update = useSmileIDSampleProfileStore((state) => state.update);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);
  const remove = useSmileIDSampleProfileStore((state) => state.delete);
  const [edit, setEdit] = useState<UseSmileIDSampleProfileEdit | null>(null);
  // Keyed by profile like `edit`, so an unsaved value never reaches another profile's page.
  const [callbackEdit, setCallbackEdit] = useState<{ profileId: string; value: string } | null>(null);
  const [organisationEdit, setOrganisationEdit] = useState<{ profileId: string; value: string } | null>(null);
  const leaving = useRef(false);
  const live = useSmileIDSampleSessionStore((state) => state.live);

  // A link to a profile this device does not hold goes back, rather than to an empty page; a delete already went.
  useEffect(() => {
    if (profile === undefined && !leaving.current) {
      leaving.current = true;
      back();
    }
  }, [profile, back]);

  if (profile === undefined || profileId === undefined) return null;

  const editedCallbackUrl = callbackEdit?.profileId === profileId ? callbackEdit.value : undefined;
  const editedOrganisation = organisationEdit?.profileId === profileId ? organisationEdit.value : undefined;
  const defaults = smileIDSampleEditorDefaults(edit, profileId, profile.defaults);
  const organisation = editedOrganisation ?? profile.organisation;
  const callbackUrl = editedCallbackUrl ?? profile.callbackUrl ?? '';
  const changed =
    organisation.trim() !== profile.organisation ||
    JSON.stringify(defaults) !== JSON.stringify(profile.defaults) ||
    callbackUrl.trim() !== (profile.callbackUrl ?? '');

  return (
    <ProfileConfigScreen
      state={{
        title: smileIDSampleProfileTitle(profile),
        organisation,
        defaults,
        isActive: profileId === activeId,
        changed,
        callbackUrl,
        callbackOverride: live === null ? null : smileIDSampleCallbackOverrideCaption(live),
      }}
      onFieldChange={(field, value) => setEdit({ profileId, details: smileIDSampleUserFieldWrite(field, defaults, value) })}
      onCallbackUrlChange={(value) => setCallbackEdit({ profileId, value })}
      onOrganisationChange={(value) => setOrganisationEdit({ profileId, value })}
      onBack={() => back()}
      onSave={() => {
        // On another profile the one CTA reads "Use this profile", so it saves and activates.
        update(profileId, { organisation, defaults, callbackUrl });
        setActive(profileId);
        back();
      }}
      onDelete={() => {
        leaving.current = true;
        remove(profileId);
        back();
      }}
    />
  );
}
