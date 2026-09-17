import type { SmileIconName } from '../smile-icons';

/// One ABOUT or LEGAL row: an id, a title, the line beneath it, and where it goes.
export type UseSmileIDSampleNavRow = {
  readonly id: string;
  readonly title: string;
  readonly supportingText?: string;
  readonly icon: SmileIconName;
  /// Opened externally. Absent means the app handles the row itself, which only the licences row does.
  readonly url?: string;
  /// False for a destination the in-app browser cannot render, which both legal pages are.
  readonly opensInApp: boolean;
};

const aboutRows: readonly UseSmileIDSampleNavRow[] = [
  {
    id: 'documentation',
    title: 'Documentation',
    supportingText: 'docs.usesmileid.com',
    icon: 'docs',
    url: 'https://docs.usesmileid.com/',
    opensInApp: true,
  },
  {
    id: 'support',
    title: 'Support',
    supportingText: 'Contact the Smile team',
    icon: 'support',
    url: 'https://smile.id/contact-us',
    opensInApp: true,
  },
];

const legalRows: readonly UseSmileIDSampleNavRow[] = [
  // Both of these serve their document as an embedded PDF, so they leave the app.
  {
    id: 'terms',
    title: 'Terms of Service',
    icon: 'terms',
    url: 'https://smile.id/terms-and-conditions',
    opensInApp: false,
  },
  {
    id: 'privacy',
    title: 'Privacy Policy',
    icon: 'privacy',
    url: 'https://smile.id/privacy-policy',
    opensInApp: false,
  },
  // No url: Apache-2.0 §4 asks the notice to travel with the distribution, so it is a screen here.
  { id: 'licenses', title: 'Open-source licenses', icon: 'licenses', opensInApp: true },
];

export const smileIDSampleAboutRows = aboutRows;
export const smileIDSampleLegalRows = legalRows;

/// The rows in the order the design draws them, so a caller can assert the set rather than the screen.
export const smileIDSampleNavRows: readonly UseSmileIDSampleNavRow[] = [...aboutRows, ...legalRows];
