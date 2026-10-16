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
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect } from 'react';

import {
  smileIDSampleCatalogueStore,
  smileIDSampleEnsureEnabled,
} from '../../../src/catalogue/use-smile-id-sample-catalogue';
import { smileIDSampleStepAfterUserDetails } from '../../../src/flow/use-smile-id-sample-flow-journey';
import {
  smileIDSampleLiveBindingsNow,
  useSmileIDSampleLiveBindings,
} from '../../../src/flow/use-smile-id-sample-token-binding-rules';
import { useLaunchArgs } from '../../../src/use-smile-id-sample-launch';
import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';

export default function ConsentDetailsForm() {
  const strings = useSmileIDSampleStrings();
  const router = useRouter();
  const back = useSmileIDSampleBack('/products');
  const { productId } = useLocalSearchParams<{ productId: string }>();
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
  const { scenario, catalogue } = useLaunchArgs();
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
      onProfilePress={() => router.push('/profiles/switch')}
      onBack={() => back()}
      onContinue={() => {
        if (saveToProfile) keep(details, organisation, requirement);
        router.push(
          product === null
            ? `/flow/${productId}/run`
            : smileIDSampleStepAfterUserDetails(product, smileIDSampleLiveBindingsNow(scenario)),
        );
      }}
    />
  );
}
