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
  type UseSmileIDSampleFlowRoute,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleProfile,
} from '@smileid/sample-ui';

import {
  smileIDSampleCatalogueEnvironment,
  smileIDSampleCatalogueLocale,
  smileIDSampleCatalogueStore,
  smileIDSampleEnsureEnabled,
} from '../catalogue/use-smile-id-sample-catalogue';
import { smileIDSampleEntryFor } from '../flow/use-smile-id-sample-flow-journey';
import {
  smileIDSampleStartRun,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { useLaunchArgs } from '../use-smile-id-sample-launch';
import { useSmileIDSampleListInset } from '../use-smile-id-sample-list-inset';

/// The products grid, where every run starts: a tap goes to the scanner without a live session, else to the run's first form.
export const UseSmileIDSampleProductsStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const engine = useSmileIDSampleEngine();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();
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
      onProductPress={(product) =>
        smileIDSampleStartProductRun(engine, scope, product, { profile, route, scenario, catalogue })
      }
      onProfilePress={() => scope.navigator.go('profileSwitch')}
      onScanPress={() => scope.navigator.go('scanToken')}
      bottomInset={bottomInset}
    />
  );
};

/// What a product tap reads from the launch and the active profile.
type UseSmileIDSampleProductRunContext = {
  readonly profile: UseSmileIDSampleProfile | null;
  readonly route: UseSmileIDSampleFlowRoute;
  readonly scenario: string;
  readonly catalogue: Parameters<typeof smileIDSampleCatalogueStore>[0];
};

/// A product tap's run from `scope`'s entry, in place of `replace` if given: fresh forms, the run's partner, and the scanner first with no live session.
export const smileIDSampleStartProductRun = (
  engine: ReturnType<typeof useSmileIDSampleEngine>,
  scope: UseSmileIDSampleStepScope,
  product: UseSmileIDSampleProduct,
  { profile, route, scenario, catalogue }: UseSmileIDSampleProductRunContext,
  replace?: number,
): void => {
  // Fresh from the profile, so one run's ID details never carry into another, least of all another partner's.
  useSmileIDSampleFormsStore.getState().startRun(profile);
  const run = smileIDSampleEntryFor(engine.graph, product, route, scenario);
  if (run === null) {
    scope.navigator.go('scanToken', undefined, replace);
    return;
  }
  // Fetched ahead, so the list is usually there by the time the picker opens.
  if (smileIDSampleCatalogueFamily(product) !== null) {
    const live = smileIDSampleLiveSession(useSmileIDSampleSessionStore.getState(), Date.now());
    const store = smileIDSampleCatalogueStore(catalogue);
    store.getState().begin(smileIDSampleCatalogueEnvironment(live), smileIDSampleCatalogueLocale());
    smileIDSampleEnsureEnabled(store, product.id, live);
  }
  smileIDSampleStartRun(engine, scope.entry, product, run, replace);
};
