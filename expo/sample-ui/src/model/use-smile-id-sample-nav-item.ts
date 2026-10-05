import type { SmileIconName } from '../smile-icons';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// One nav destination: its id, its label and the design's own mark for it.
export type UseSmileIDSampleNavItem = {
  readonly id: string;
  readonly testID: string;
  readonly label: (strings: UseSmileIDSampleStrings) => string;
  readonly icon: SmileIconName;
};

/// The three destinations the nav bar switches between. The token affordance is not one of them.
export const smileIDSampleNavItems: readonly UseSmileIDSampleNavItem[] = [
  {
    id: 'products',
    testID: UseSmileIDSampleTestIds.NAV_PRODUCTS,
    label: (strings) => strings.navProducts,
    icon: 'products',
  },
  {
    id: 'verifications',
    testID: UseSmileIDSampleTestIds.NAV_VERIFICATIONS,
    label: (strings) => strings.navVerifications,
    icon: 'verifications',
  },
  {
    id: 'settings',
    testID: UseSmileIDSampleTestIds.NAV_SETTINGS,
    label: (strings) => strings.navSettings,
    icon: 'settings',
  },
];
