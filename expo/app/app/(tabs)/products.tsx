import {
  ProductsScreen,
  smileIDSampleCatalogueFamily,
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
import {
  smileIDSampleCatalogueEnvironment,
  smileIDSampleCatalogueLocale,
  smileIDSampleCatalogueStore,
} from '../../src/catalogue/use-smile-id-sample-catalogue';
import { useLaunchArgs } from '../../src/use-smile-id-sample-launch';
import { useSmileIDSampleListInset } from '../../src/use-smile-id-sample-list-inset';

export default function Products() {
  const router = useRouter();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();
  const startRun = useSmileIDSampleFormsStore((state) => state.startRun);
  const bottomInset = useSmileIDSampleListInset();
  const { scenario, theme, catalogue, route } = useLaunchArgs();
  const sendRun = useSmileIDSampleSessionStore((state) => state.sendRun);
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
        startRun(profile);
        if (smileIDSampleLiveSession(useSmileIDSampleSessionStore.getState(), Date.now()) === null) {
          sendRun({ productId: product.id, route, resumeAt: 'firstStep' });
          router.push('/token/scan');
          return;
        }
        // Fetched ahead, so the list is usually there by the time the picker opens.
        if (smileIDSampleCatalogueFamily(product) !== null) {
          smileIDSampleCatalogueStore(catalogue)
            .getState()
            .begin(smileIDSampleCatalogueEnvironment(live), smileIDSampleCatalogueLocale());
        }
        router.push(smileIDSampleFirstStepFor(product, smileIDSampleLiveBindingsNow(scenario)));
      }}
      onProfilePress={() => router.push('/profiles/switch')}
      onScanPress={() => router.push('/token/scan')}
      bottomInset={bottomInset}
    />
  );
}
