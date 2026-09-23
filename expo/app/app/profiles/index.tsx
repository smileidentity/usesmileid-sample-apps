import {
  ProfilesScreen,
  UseSmileIDSampleTransientNoticeHost,
  useSmileIDSampleProfileStore,
  useSmileIDSampleTransientNotice,
} from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';
import { useSmileIDSampleNoticeInset } from '../../src/use-smile-id-sample-notice-inset';
import { useEffect } from 'react';
import { StyleSheet, View } from 'react-native';

export default function Profiles() {
  const router = useRouter();
  const back = useSmileIDSampleBack('/settings');
  const notice = useSmileIDSampleTransientNotice();
  const noticeInset = useSmileIDSampleNoticeInset();
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
      message: `${created.organisation} created`,
      actionLabel: 'Make active',
      onAction: () => setActive(created.id),
    });
  }, [lastCreatedId, profiles, clearLastCreated, setActive, show]);

  return (
    <View style={styles.host}>
      <ProfilesScreen
        state={{ profiles, activeId }}
        onProfilePress={(profile) => router.push(`/profiles/${profile.id}`)}
        onCreate={() => router.push('/profiles/new')}
        onBack={() => back()}
      />
      <UseSmileIDSampleTransientNoticeHost state={notice} style={[styles.notice, { bottom: noticeInset }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  host: { flex: 1 },
  notice: { paddingHorizontal: 16, position: 'absolute' },
});
