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

import { smileIDSampleEntryFor } from '../../src/flow/use-smile-id-sample-flow-journey';
import {
  smileIDSampleCatalogueEnvironment,
  smileIDSampleCatalogueLocale,
  smileIDSampleCatalogueStore,
  smileIDSampleEnsureEnabled,
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
        const entry = smileIDSampleEntryFor(product, route, scenario);
        // Fetched ahead, so the list is usually there by the time the picker opens.
        if (entry !== '/token/scan' && smileIDSampleCatalogueFamily(product) !== null) {
          const store = smileIDSampleCatalogueStore(catalogue);
          store.getState().begin(smileIDSampleCatalogueEnvironment(live), smileIDSampleCatalogueLocale());
          smileIDSampleEnsureEnabled(store, product.id, live);
        }
        router.push(entry);
      }}
      onProfilePress={() => router.push('/profiles/switch')}
      onScanPress={() => router.push('/token/scan')}
      bottomInset={bottomInset}
    />
  );
}
