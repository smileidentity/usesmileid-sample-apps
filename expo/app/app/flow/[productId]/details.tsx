import {
  UserDetailsScreen,
  smileIDSampleProductFrom,
  smileIDSampleRequirementFrom,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
  useSmileIDSampleFormsStore,
  useSmileIDSampleProfileStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect } from 'react';

import { smileIDSampleStepAfterUserDetails } from '../../../src/flow/use-smile-id-sample-flow-journey';
import {
  smileIDSampleLiveBindingsNow,
  useSmileIDSampleLiveBindings,
} from '../../../src/flow/use-smile-id-sample-token-binding-rules';
import { useLaunchArgs } from '../../../src/use-smile-id-sample-launch';
import { useSmileIDSampleBack } from '../../../src/use-smile-id-sample-back';

export default function ConsentDetailsForm() {
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
  const { scenario } = useLaunchArgs();
  const requirement = smileIDSampleRequirementFrom(bindings);

  // A cold link arrives without the product tap that fills the form, so entry fills it too.
  useEffect(() => {
    const active = useSmileIDSampleProfileStore.getState();
    const current = active.items.find((item) => item.id === active.activeId);
    if (current !== undefined) useSmileIDSampleFormsStore.getState().fillFrom(current);
  }, []);

  return (
    <UserDetailsScreen
      state={{
        productLabel: product?.label ?? productId ?? '',
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
      onProfilePress={() => router.push('/profiles/switch?fromForm=1')}
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
