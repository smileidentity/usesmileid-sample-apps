import { LicensesScreen, type UseSmileIDSampleLicence } from '@smileid/sample-ui';
import licences from '@smileid/sample-ui/src/assets/licenses.json';
import { useRouter } from 'expo-router';

/// Generated into the bundle by scripts/generate_expo_licenses.py; an empty list means it did not ship.
const components = (licences.components ?? []) as readonly UseSmileIDSampleLicence[];

export default function Licenses() {
  const router = useRouter();
  return <LicensesScreen licences={components} onBack={() => router.back()} />;
}
