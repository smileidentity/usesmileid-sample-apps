import {
  UserDetailsScreen,
  smileIDSampleProductFrom,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleFormsStore,
  useSmileIDSampleProfileStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';

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

  return (
    <UserDetailsScreen
      state={{
        productLabel: product?.label ?? productId ?? '',
        details,
        rememberDetails,
      }}
      onFieldChange={setUserField}
      onRememberChange={setRememberDetails}
      onBack={() => back()}
      onContinue={() => {
        // The switch says "remember these for next time", and the profile's defaults are where next time reads.
        if (rememberDetails) setDefaults(profile.id, details);
        if (product?.needsIdDetails === true) {
          router.push(`/flow/${productId}/id-details`);
          return;
        }
        router.push(`/flow/${productId}/run`);
      }}
    />
  );
}
