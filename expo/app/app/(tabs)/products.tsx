import {
  ProductsScreen,
  smileIDSampleResultSelecting,
  useSmileIDSampleResultStore,
  avatarColorForProfile,
  smileIDSampleCountdown,
  smileIDSampleLiveSession,
  smileIDSampleProfileInitials,
  smileIDSampleSessionExpired,
  smileIDSampleSessionRemaining,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
  useSmileIDSampleSessionStore,
  useSmileIDSampleFormsStore,
} from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

import { smileIDSampleFirstStepFor } from '../../src/flow/use-smile-id-sample-flow-journey';
import { smileIDSampleLiveBindingsNow } from '../../src/flow/use-smile-id-sample-token-binding-rules';
import { useLaunchArgs } from '../../src/use-smile-id-sample-launch';
import { useSmileIDSampleListInset } from '../../src/use-smile-id-sample-list-inset';

export default function Products() {
  const router = useRouter();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();
  const fillFrom = useSmileIDSampleFormsStore((state) => state.fillFrom);
  const bottomInset = useSmileIDSampleListInset();
  const { scenario, theme } = useLaunchArgs();
  const result = useSmileIDSampleResultStore((state) => state.result);
  const live = useSmileIDSampleSessionStore((state) => smileIDSampleLiveSession(state, state.nowMillis));
  const nowMillis = useSmileIDSampleSessionStore((state) => state.nowMillis);
  const ended = useSmileIDSampleSessionStore((state) => smileIDSampleSessionExpired(state, state.nowMillis));

  return (
    <ProductsScreen
      state={{
        initials: profile === null ? '' : smileIDSampleProfileInitials(profile),
        result: smileIDSampleResultSelecting(result, scenario, theme),
        avatarColor: avatarColorForProfile(index),
        sessionId: live?.id ?? null,
        sessionRemaining: live === null ? null : smileIDSampleCountdown(smileIDSampleSessionRemaining(live, nowMillis)),
        sessionEnded: ended,
      }}
      onProductPress={(product) => {
        // Every run starts from the active profile, including one whose form the token skips; with none,
        // what this session typed stays, since the person chose not to keep it.
        if (profile !== null) fillFrom(profile);
        router.push(smileIDSampleFirstStepFor(product, smileIDSampleLiveBindingsNow(scenario)));
      }}
      onProfilePress={() => router.push('/profiles/switch')}
      onScanPress={() => router.push('/token/scan')}
      bottomInset={bottomInset}
    />
  );
}
