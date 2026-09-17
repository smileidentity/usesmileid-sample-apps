import {
  KycIdFormScreen,
  smileIDSampleProductFrom,
  useSmileIDSampleFormsStore,
} from '@smileid/sample-ui';
import { useLocalSearchParams, useRouter } from 'expo-router';

export default function IdDetailsForm() {
  const router = useRouter();
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const product = smileIDSampleProductFrom(productId);
  const details = useSmileIDSampleFormsStore((state) => state.idDetails);
  const setIdNumber = useSmileIDSampleFormsStore((state) => state.setIdNumber);

  return (
    <KycIdFormScreen
      state={{ productLabel: product?.label ?? productId ?? '', details }}
      onCountryPress={() => router.push(`/flow/${productId}/id-details/country`)}
      onIdTypePress={() => router.push(`/flow/${productId}/id-details/id-type`)}
      onIdNumberChange={setIdNumber}
      onBack={() => router.back()}
      onContinue={() => router.push(`/flow/${productId}/run`)}
      onTokenPress={() => router.push('/token/scan')}
    />
  );
}
