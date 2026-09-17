import { ProfileSwitchSheet, useSmileIDSampleProfileStore } from '@smileid/sample-ui';

import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';

/// Grouped under products rather than the profiles list: routes.json names products as its owner.
export default function ProfileSwitch() {
  const back = useSmileIDSampleBack('/products');
  const profiles = useSmileIDSampleProfileStore((state) => state.items);
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);

  return (
    <ProfileSwitchSheet
      profiles={profiles}
      activeId={activeId}
      onSelect={(profile) => {
        setActive(profile.id);
        back();
      }}
      onDismiss={() => back()}
    />
  );
}
