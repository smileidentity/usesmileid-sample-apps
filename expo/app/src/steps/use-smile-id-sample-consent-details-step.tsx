import {
  UserDetailsScreen,
  smileIDSampleCatalogueFieldsToCollectOf,
  smileIDSampleCatalogueIdTypeFieldsOf,
  smileIDSampleLiveSession,
  smileIDSampleProductFrom,
  smileIDSampleRequirementFor,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
  useSmileIDSampleFormsStore,
  useSmileIDSampleProfileStore,
  useSmileIDSampleSessionStore,
  smileIDSampleProductTitle,
  useSmileIDSampleStrings,
} from '@smileid/sample-ui';
import { useEffect } from 'react';

import { smileIDSampleCatalogueStore, smileIDSampleEnsureEnabled } from '../catalogue/use-smile-id-sample-catalogue';
import { useSmileIDSampleLiveBindings } from '../flow/use-smile-id-sample-token-binding-rules';
import {
  smileIDSampleRunProductId,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { useLaunchArgs } from '../use-smile-id-sample-launch';

/// The details every product collects before its flow; Continue takes the run's next form, or the run.
export const UseSmileIDSampleConsentDetailsStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const strings = useSmileIDSampleStrings();
  const productId = smileIDSampleRunProductId(useSmileIDSampleEngine(), scope.entry);
  const product = smileIDSampleProductFrom(productId);
  const profile = useSmileIDSampleActiveProfile();
  const profileIndex = useSmileIDSampleActiveProfileIndex();
  const details = useSmileIDSampleFormsStore((state) => state.userDetails);
  const saveToProfile = useSmileIDSampleFormsStore((state) => state.saveToProfile);
  const organisation = useSmileIDSampleFormsStore((state) => state.organisation);
  const setUserField = useSmileIDSampleFormsStore((state) => state.setUserField);
  const setSaveToProfile = useSmileIDSampleFormsStore((state) => state.setSaveToProfile);
  const setOrganisation = useSmileIDSampleFormsStore((state) => state.setOrganisation);
  const keep = useSmileIDSampleProfileStore((state) => state.keep);
  const bindings = useSmileIDSampleLiveBindings();
  const { catalogue } = useLaunchArgs();
  const store = smileIDSampleCatalogueStore(catalogue);
  const liveSessionId = useSmileIDSampleSessionStore(
    (state) => smileIDSampleLiveSession(state, state.nowMillis)?.id ?? null,
  );
  const fieldsToCollect = store((state) => smileIDSampleCatalogueFieldsToCollectOf(state, liveSessionId));
  const idTypeFields = store((state) => smileIDSampleCatalogueIdTypeFieldsOf(state, liveSessionId));
  const requirement = smileIDSampleRequirementFor(bindings, product, fieldsToCollect, idTypeFields);

  // A link lands here without the product tap that asks ahead, and the configuration decides which rows show.
  useEffect(() => {
    const sessions = useSmileIDSampleSessionStore.getState();
    smileIDSampleEnsureEnabled(store, productId, smileIDSampleLiveSession(sessions, sessions.nowMillis));
  }, [store, productId, liveSessionId]);

  const fillFrom = useSmileIDSampleFormsStore((state) => state.fillFrom);
  useEffect(() => {
    if (profile !== null) fillFrom(profile);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <UserDetailsScreen
      state={{
        productLabel: product === null ? (productId ?? '') : smileIDSampleProductTitle(product, strings),
        details,
        profile,
        profileIndex,
        saveToProfile,
        organisation,
        requirement,
      }}
      onFieldChange={setUserField}
      onSaveToProfileChange={setSaveToProfile}
      onOrganisationChange={setOrganisation}
      onProfilePress={() => scope.navigator.go('profileSwitch')}
      onBack={() => scope.navigator.back()}
      onContinue={() => {
        if (saveToProfile) keep(details, organisation, requirement);
        scope.navigator.next();
      }}
    />
  );
};
