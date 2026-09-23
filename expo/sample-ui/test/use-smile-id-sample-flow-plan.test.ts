import { smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { smileIDSampleFlowPlan } from '../src/state/use-smile-id-sample-flow-plan';
import type {
  UseSmileIDSampleTokenBindings,
  UseSmileIDSampleTokenConsent,
} from '../src/state/use-smile-id-sample-token-decoder';

/// The truth table from token-binding-matrix-android.md §7, enumerated rather than sampled.
const complete: UseSmileIDSampleTokenConsent = {
  granted: true,
  grantedAt: '2026-08-18T09:00:00Z',
  noticeLanguage: 'en',
  noticePrivacyPolicyUrl: 'https://smile.id/privacy-policy',
};
const consents: Record<string, UseSmileIDSampleTokenConsent | null> = {
  absent: null,
  complete,
  partial: { ...complete, noticeLanguage: null },
};
const details: Record<string, UseSmileIDSampleTokenBindings> = {
  none: {},
  namesOnly: { givenNames: true, lastName: true },
  contactOnly: { email: true },
  namesAndContact: { givenNames: true, lastName: true, phoneNumber: true },
};
const idClaims: UseSmileIDSampleTokenBindings = { country: 'KE', idType: 'NATIONAL_ID', idNumberReference: 'vault_id' };

const rows = Object.entries(consents).flatMap(([consentName, consent]) =>
  Object.entries(details).flatMap(([detailName, detail]) =>
    [true, false].flatMap((bindsId) =>
      smileIDSampleProducts.map((product) => ({ consentName, consent, detailName, detail, bindsId, product })),
    ),
  ),
);

describe('the flow plan', () => {
  it.each(rows)(
    'consent $consentName, details $detailName, id bound $bindsId, $product.id',
    ({ consent, detail, detailName, bindsId, product }) => {
      const plan = smileIDSampleFlowPlan({ ...detail, ...(bindsId ? idClaims : {}), consent }, product);
      // A partial binding is still a binding: the SDK fails the build naming what is missing (case 7).
      expect(plan.declareConsentScreen).toBe(consent === null);
      expect(plan.passUserDetails).toBe(detailName !== 'namesAndContact');
      expect(plan.userDetailsGap).toEqual({
        firstName: detail.givenNames !== true,
        lastName: detail.lastName !== true,
        contact: detail.email !== true && detail.phoneNumber !== true,
      });
      expect(plan.showIdDetailsForm).toBe(product.needsIdDetails && !bindsId);
    },
  );

  it('with no token asks for everything and declares the consent screen', () => {
    for (const product of smileIDSampleProducts) {
      expect(smileIDSampleFlowPlan(null, product)).toEqual({
        userDetailsGap: { firstName: true, lastName: true, contact: true },
        showIdDetailsForm: product.needsIdDetails,
        declareConsentScreen: true,
        passUserDetails: true,
      });
    }
  });

  it('shows the Document Verification form when only the country is bound', () => {
    const document = smileIDSampleProducts.find((product) => product.id === 'documentVerification')!;
    expect(smileIDSampleFlowPlan({ country: 'KE' }, document).showIdDetailsForm).toBe(true);
  });

  it('enumerates every row the matrix names', () => {
    expect(rows).toHaveLength(3 * 4 * 2 * smileIDSampleProducts.length);
  });
});
