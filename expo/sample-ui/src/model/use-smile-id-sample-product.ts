import { smileProductHues, type SmileProductHue } from '../smile-product-hues';
import type { SmileIconName } from '../smile-icons';
import { UseSmileIDSampleMarks } from '../use-smile-id-sample-marks';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

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
    id: 'residencyDocumentVerification',
    label: 'Residency Document Verification',
    cardTitle: 'Residency Doc.',
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

/// Every product has its own mark; the two document products deliberately share one, told apart by hue.
export const smileIDSampleProductIcon = (product: UseSmileIDSampleProduct): SmileIconName => {
  switch (product.id) {
    case 'smartSelfieEnrollment':
      return 'smartSelfieEnrollment';
    case 'smartSelfieAuth':
      return 'smartSelfieAuth';
    case 'documentVerification':
    case 'enhancedDocumentVerification':
      return 'documentVerification';
    case 'residencyDocumentVerification':
      return 'residencyDocumentVerification';
    case 'biometricKyc':
      return 'biometricKyc';
    default:
      return 'enhancedKyc';
  }
};

/// The product's colouring, which lives in spec/design-tokens.json rather than the design system.
export const smileIDSampleProductHue = (product: UseSmileIDSampleProduct): SmileProductHue => {
  const hue = smileProductHues[product.id];
  if (!hue) {
    throw new Error(`no hue for product '${product.id}'; see spec/design-tokens.json → productHues`);
  }
  return hue;
};

/// Resolves a product id from a launch argument or a route, returning null rather than throwing.
export const smileIDSampleProductFrom = (id: string | null | undefined) =>
  smileIDSampleProducts.find((product) => product.id === id) ?? null;

/// A section's heading in the app's language.
export const smileIDSampleProductSectionLabel = (
  section: UseSmileIDSampleProductSectionKey,
  strings: UseSmileIDSampleStrings,
): string => (section === 'Authentication' ? strings.productsSectionAuthentication : strings.productsSectionOnboarding);

/// The product's name in the app's language.
export const smileIDSampleProductTitle = (product: UseSmileIDSampleProduct, strings: UseSmileIDSampleStrings): string => {
  switch (product.id) {
    case 'smartSelfieEnrollment':
      return strings.productSmartSelfieEnrollment;
    case 'smartSelfieAuth':
      return strings.productSmartSelfieAuthentication;
    case 'documentVerification':
      return strings.productDocumentVerification;
    case 'enhancedDocumentVerification':
      return strings.productEnhancedDocumentVerification;
    case 'residencyDocumentVerification':
      return strings.productResidencyDocumentVerification;
    case 'biometricKyc':
      return strings.productBiometricKyc;
    case 'enhancedKyc':
      return strings.productEnhancedKyc;
    default:
      return product.label;
  }
};

/// The card's first line in the app's language.
export const smileIDSampleProductCardTitle = (product: UseSmileIDSampleProduct, strings: UseSmileIDSampleStrings): string => {
  switch (product.id) {
    case 'smartSelfieEnrollment':
      return strings.productCardRegistration;
    case 'smartSelfieAuth':
      return strings.productCardAuth;
    case 'documentVerification':
      return strings.productCardDocument;
    case 'enhancedDocumentVerification':
      return strings.productCardEnhancedDoc;
    case 'residencyDocumentVerification':
      return strings.productCardResidencyDoc;
    case 'biometricKyc':
      return strings.productCardBiometric;
    case 'enhancedKyc':
      return strings.productCardEnhanced;
    default:
      return product.cardTitle;
  }
};

/// The card's second line; the SmartSelfie mark is never translated.
export const smileIDSampleProductCardFamily = (product: UseSmileIDSampleProduct, strings: UseSmileIDSampleStrings): string => {
  if (product.cardFamily === UseSmileIDSampleMarks.SMART_SELFIE) return product.cardFamily;
  return product.cardFamily === 'KYC' ? strings.productFamilyKyc : strings.productFamilyVerification;
};
