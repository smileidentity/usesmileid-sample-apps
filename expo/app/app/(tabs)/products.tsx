import {
  ProductsScreen,
  avatarColorForProfile,
  smileIDSampleProfileInitials,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
} from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

import { useSmileIDSampleListInset } from '../../src/use-smile-id-sample-list-inset';

export default function Products() {
  const router = useRouter();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();
  const bottomInset = useSmileIDSampleListInset();

  return (
    <ProductsScreen
      state={{
        initials: smileIDSampleProfileInitials(profile),
        avatarColor: avatarColorForProfile(index),
      }}
      // Every product shows the Consent Details Form first, which is sample-owned.
      onProductPress={(product) => router.push(`/flow/${product.id}/details`)}
      onProfilePress={() => router.push('/profiles/switch')}
      onScanPress={() => router.push('/token/scan')}
      bottomInset={bottomInset}
    />
  );
}
