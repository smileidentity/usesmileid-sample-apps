import {
  ProductsScreen,
  avatarColorForProfile,
  smileIDSampleProfileInitials,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
} from '@smileid/sample-ui';
import { useRouter } from 'expo-router';

export default function Products() {
  const router = useRouter();
  const profile = useSmileIDSampleActiveProfile();
  const index = useSmileIDSampleActiveProfileIndex();

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
    />
  );
}
