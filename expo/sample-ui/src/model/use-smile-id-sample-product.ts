import { UseSmileIDSampleMarks } from '../use-smile-id-sample-marks';

/// Constant keys outlive their labels: the second section is the Onboarding heading, not the Verifications tab.
export const UseSmileIDSampleProductSection = {
  Authentication: 'Authentication',
  Verifications: 'Onboarding',
} as const;

export type UseSmileIDSampleProductSectionKey = keyof typeof UseSmileIDSampleProductSection;

/// One product card. `label` is the SDK's job-type name in full; `cardTitle` and `cardFamily` are the card's two runs.
export type UseSmileIDSampleProduct = {
  readonly id: string;
  readonly label: string;
  readonly cardTitle: string;
  readonly cardFamily: string;
  readonly section: UseSmileIDSampleProductSectionKey;
  readonly capture: boolean;
  readonly needsIdDetails: boolean;
};

/// The products grid in design order, asserted against `spec/scenarios.json` by a unit test.
export const smileIDSampleProducts: readonly UseSmileIDSampleProduct[] = [
  {
    id: 'smartSelfieEnrollment',
    label: 'SmartSelfie Enrollment',
    cardTitle: 'Registration',
    cardFamily: UseSmileIDSampleMarks.SMART_SELFIE,
    section: 'Authentication',
    capture: true,
    needsIdDetails: false,
  },
  {
    id: 'smartSelfieAuth',
    label: 'SmartSelfie Authentication',
    cardTitle: 'Auth',
    cardFamily: UseSmileIDSampleMarks.SMART_SELFIE,
    section: 'Authentication',
    capture: true,
    needsIdDetails: false,
  },
  {
    id: 'documentVerification',
    label: 'Document Verification',
    cardTitle: 'Document',
    cardFamily: 'Verification',
    section: 'Verifications',
    capture: true,
    needsIdDetails: true,
  },
  {
    id: 'enhancedDocumentVerification',
    label: 'Enhanced Document Verification',
    cardTitle: 'Enhanced Doc.',
    cardFamily: 'Verification',
    section: 'Verifications',
    capture: true,
    needsIdDetails: true,
  },
  {
    id: 'biometricKyc',
    label: 'Biometric KYC',
    cardTitle: 'Biometric',
    cardFamily: 'KYC',
    section: 'Verifications',
    capture: true,
    needsIdDetails: true,
  },
  {
    id: 'enhancedKyc',
    label: 'Enhanced KYC',
    cardTitle: 'Enhanced',
    cardFamily: 'KYC',
    section: 'Verifications',
    capture: false,
    needsIdDetails: true,
  },
] as const;

/// The products of one section, in design order.
export const smileIDSampleProductsOf = (
  section: UseSmileIDSampleProductSectionKey,
): readonly UseSmileIDSampleProduct[] => smileIDSampleProducts.filter((p) => p.section === section);

/// Resolves a product id from a launch argument or a route, returning null rather than throwing.
export const smileIDSampleProductFrom = (id: string | null | undefined) =>
  smileIDSampleProducts.find((product) => product.id === id) ?? null;
