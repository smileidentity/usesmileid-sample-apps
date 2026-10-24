import { LicensesScreen, type UseSmileIDSampleLicence } from '@smileid/sample-ui';
import licences from '@smileid/sample-ui/src/assets/licenses.json';

import type { UseSmileIDSampleStepScope } from '../navigation/use-smile-id-sample-navigation';

/// Generated into the bundle by scripts/generate_expo_licenses.py; an empty list means it did not ship.
const components = (licences.components ?? []) as readonly UseSmileIDSampleLicence[];

/// The third-party notices, inside settings.
export const UseSmileIDSampleLicensesStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => (
  <LicensesScreen licences={components} onBack={() => scope.navigator.back()} />
);
