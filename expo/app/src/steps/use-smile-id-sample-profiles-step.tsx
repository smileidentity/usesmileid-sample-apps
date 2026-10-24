import {
  ProfilesScreen,
  UseSmileIDSampleTransientNoticeHost,
  useSmileIDSampleProfileStore,
  useSmileIDSampleTransientNotice,
 useSmileIDSampleStrings } from '@smileid/sample-ui';
import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';

import type { UseSmileIDSampleStepScope } from '../navigation/use-smile-id-sample-navigation';
import { useSmileIDSampleNoticeStyle } from '../use-smile-id-sample-notice-inset';

/// The profiles list, which confirms a profile the new-profile sheet made over it.
export const UseSmileIDSampleProfilesStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const strings = useSmileIDSampleStrings();
  const notice = useSmileIDSampleTransientNotice();
  const noticeStyle = useSmileIDSampleNoticeStyle();
  const profiles = useSmileIDSampleProfileStore((state) => state.items);
  const activeId = useSmileIDSampleProfileStore((state) => state.activeId);
  const lastCreatedId = useSmileIDSampleProfileStore((state) => state.lastCreatedId);
  const clearLastCreated = useSmileIDSampleProfileStore((state) => state.clearLastCreated);
  const setActive = useSmileIDSampleProfileStore((state) => state.setActive);
  const { show } = notice;

  // Consumed on sight, so returning to the list cannot re-show it.
  useEffect(() => {
    if (lastCreatedId === null) return;
    const created = profiles.find((profile) => profile.id === lastCreatedId);
    clearLastCreated();
    if (created === undefined) return;
    // Creating a profile does not make it active, so the confirmation carries the offer.
    show({
      message: strings.profilesCreated({ profile: created.organisation }),
      actionLabel: strings.profilesMakeActive,
      onAction: () => setActive(created.id),
    });
  }, [lastCreatedId, profiles, clearLastCreated, setActive, show, strings]);

  return (
    <View style={styles.host}>
      <ProfilesScreen
        state={{ profiles, activeId }}
        onProfilePress={(profile) => scope.navigator.go('profileConfig', profile.id)}
        onCreate={() => scope.navigator.go('newProfile')}
        onBack={() => scope.navigator.back()}
      />
      <UseSmileIDSampleTransientNoticeHost state={notice} style={noticeStyle} />
    </View>
  );
};

const styles = StyleSheet.create({
  host: { flex: 1 },
});
