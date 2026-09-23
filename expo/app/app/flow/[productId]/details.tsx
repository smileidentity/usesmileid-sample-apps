import {
  UserDetailsScreen,
  smileIDSampleProductFrom,
  smileIDSampleRequirementFrom,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleFormsStore,
  useSmileIDSampleProfileStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';

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
  const details = useSmileIDSampleFormsStore((state) => state.userDetails);
  const rememberDetails = useSmileIDSampleFormsStore((state) => state.rememberDetails);
  const setUserField = useSmileIDSampleFormsStore((state) => state.setUserField);
  const setRememberDetails = useSmileIDSampleFormsStore((state) => state.setRememberDetails);
  const setDefaults = useSmileIDSampleProfileStore((state) => state.setDefaults);
  const bindings = useSmileIDSampleLiveBindings();
  const { scenario } = useLaunchArgs();

  return (
    <UserDetailsScreen
      state={{
        productLabel: product?.label ?? productId ?? '',
        details,
        rememberDetails,
        // Bound rows read "Provided by token" and never prefill: the value is vaulted and the host does not have it.
        requirement: smileIDSampleRequirementFrom(bindings),
      }}
      onFieldChange={setUserField}
      onRememberChange={setRememberDetails}
      onBack={() => back()}
      onContinue={() => {
        // The switch says "remember these for next time", and the profile's defaults are where next time reads.
        if (rememberDetails) setDefaults(profile.id, details);
        router.push(
          product === null
            ? `/flow/${productId}/run`
            : smileIDSampleStepAfterUserDetails(product, smileIDSampleLiveBindingsNow(scenario)),
        );
      }}
    />
  );
}
