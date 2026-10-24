import {
  ProfileConfigScreen,
  smileIDSampleCallbackOverrideCaption,
  smileIDSampleEditorDefaults,
  smileIDSampleProfileTitle,
  smileIDSampleUserDetailsEqual,
  smileIDSampleUserFieldWrite,
  useSmileIDSampleProfileStore,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleProfileEdit,
  useSmileIDSampleStrings,
} from '@smileid/sample-ui';
import { useCallback, useEffect, useRef, useState } from 'react';

import type { UseSmileIDSampleStepScope } from '../navigation/use-smile-id-sample-navigation';

/// One profile's own page, the profile id its entry carries; a profile that has gone leaves.
export const UseSmileIDSampleProfileConfigStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const strings = useSmileIDSampleStrings();
  const { navigator } = scope;
  const back = useCallback(() => navigator.back(), [navigator]);
  const profileId = scope.entry.arg;
  const profile = useSmileIDSampleProfileStore((state) =>
    state.items.find((item) => item.id === profileId),
  );
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const update = useSmileIDSampleProfileStore((state) => state.update);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);
  const remove = useSmileIDSampleProfileStore((state) => state.delete);
  const [edit, setEdit] = useState<UseSmileIDSampleProfileEdit | null>(null);
  const [callbackEdit, setCallbackEdit] = useState<{ profileId: string; value: string } | null>(null);
  const [organisationEdit, setOrganisationEdit] = useState<{ profileId: string; value: string } | null>(null);
  const leaving = useRef(false);
  const live = useSmileIDSampleSessionStore((state) => state.live);

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
    !smileIDSampleUserDetailsEqual(defaults, profile.defaults) ||
    callbackUrl.trim() !== (profile.callbackUrl ?? '');

  return (
    <ProfileConfigScreen
      state={{
        title: smileIDSampleProfileTitle(profile, strings),
        organisation,
        defaults,
        isActive: profileId === activeId,
        changed,
        callbackUrl,
        callbackOverride: live === null ? null : smileIDSampleCallbackOverrideCaption(live, strings),
      }}
      onFieldChange={(field, value) => setEdit({ profileId, details: smileIDSampleUserFieldWrite(field, defaults, value) })}
      onCallbackUrlChange={(value) => setCallbackEdit({ profileId, value })}
      onOrganisationChange={(value) => setOrganisationEdit({ profileId, value })}
      onBack={() => back()}
      onSave={() => {
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
};
