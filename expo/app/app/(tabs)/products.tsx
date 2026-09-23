import {
  ProductsScreen,
  avatarColorForProfile,
  smileIDSampleCountdown,
  smileIDSampleLiveSession,
  smileIDSampleProfileInitials,
  smileIDSampleSessionExpired,
  smileIDSampleSessionRemaining,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
  useSmileIDSampleSessionStore,
} from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

import { smileIDSampleFirstStepFor, useSmileIDSampleLiveBindings } from '../../src/flow/use-smile-id-sample-flow-journey';
import { useSmileIDSampleListInset } from '../../src/use-smile-id-sample-list-inset';

export default function Products() {
  const router = useRouter();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();
  const bottomInset = useSmileIDSampleListInset();
  const bindings = useSmileIDSampleLiveBindings();
  // The one screen that reads the tick, because it is the one that shows the countdown.
  const live = useSmileIDSampleSessionStore((state) => smileIDSampleLiveSession(state, state.nowMillis));
  const nowMillis = useSmileIDSampleSessionStore((state) => state.nowMillis);
  const ended = useSmileIDSampleSessionStore((state) => smileIDSampleSessionExpired(state, state.nowMillis));

  return (
    <ProductsScreen
      state={{
        initials: smileIDSampleProfileInitials(profile),
        avatarColor: avatarColorForProfile(index),
        sessionId: live?.id ?? null,
        sessionRemaining: live === null ? null : smileIDSampleCountdown(smileIDSampleSessionRemaining(live, nowMillis)),
        sessionEnded: ended,
      }}
      // Past the forms when the token already binds everything they would collect.
      onProductPress={(product) => router.push(smileIDSampleFirstStepFor(product, bindings))}
      onProfilePress={() => router.push('/profiles/switch')}
      onScanPress={() => router.push('/token/scan')}
      bottomInset={bottomInset}
    />
  );
}
