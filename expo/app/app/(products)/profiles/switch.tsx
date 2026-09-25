import { ProfileSwitchSheet, useSmileIDSampleFormsStore, useSmileIDSampleProfileStore } from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';

import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';

/// Grouped under products rather than the profiles list: routes.json names products as its owner.
export default function ProfileSwitch() {
  const back = useSmileIDSampleBack('/products');
  const router = useRouter();
  const { fromForm } = useLocalSearchParams<{ fromForm?: string }>();
  const fillFrom = useSmileIDSampleFormsStore((state) => state.fillFrom);
  const profiles = useSmileIDSampleProfileStore((state) => state.items);
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);

  return (
    <ProfileSwitchSheet
      profiles={profiles}
      activeId={activeId}
      onSelect={(profile) => {
        setActive(profile.id);
        fillFrom(profile);
        back();
      }}
      onCreate={() => router.replace(`/profiles/new?activate=1${fromForm === '1' ? '&fromForm=1' : ''}`)}
      onDismiss={() => back()}
    />
  );
}
