import {
  ProfileConfigScreen,
  smileIDSampleUserFieldWrite,
  smileIDSampleUserDetailsDefaults,
  useSmileIDSampleProfileStore,
  type UseSmileIDSampleUserDetails,
} from '@smileid/sample-ui';
import { useLocalSearchParams } from 'expo-router';

import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';
import { useState } from 'react';

export default function ProfileConfig() {
  const back = useSmileIDSampleBack('/profiles');
  const { profileId } = useLocalSearchParams<{ profileId: string }>();
  const profile = useSmileIDSampleProfileStore((state) =>
    state.items.find((item) => item.id === profileId),
  );
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const setDefaults = useSmileIDSampleProfileStore((state) => state.setDefaults);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);
  const [defaults, setLocalDefaults] = useState<UseSmileIDSampleUserDetails>(
    profile?.defaults ?? smileIDSampleUserDetailsDefaults,
  );

  return (
    <ProfileConfigScreen
      state={{
        organisation: profile?.organisation ?? profileId ?? '',
        defaults,
        isActive: profileId === activeId,
      }}
      onFieldChange={(field, value) =>
        setLocalDefaults((current) => smileIDSampleUserFieldWrite(field, current, value))
      }
      onBack={() => back()}
      onSave={() => {
        if (profileId === undefined) return;
        // The CTA reads "Make this profile active", so it has to do both.
        setDefaults(profileId, defaults);
        setActive(profileId);
        back();
      }}
    />
  );
}
