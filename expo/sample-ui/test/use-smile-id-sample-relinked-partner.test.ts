import { smileIDSampleIdDetailsDefaults, smileIDSampleIdDetailsWithEnabledOnly } from '../src/state/use-smile-id-sample-id-details';
import type { UseSmileIDSampleDocument } from '../src/state/use-smile-id-sample-id-details';
import { smileIDSampleKeepsForms, smileIDSampleResumesInFlow } from '../src/state/use-smile-id-sample-session-store';

const kenya = { code: 'KE', name: 'Kenya' };
const passport = { code: 'PASSPORT', subType: null, name: 'Passport', hasBack: false, format: 3 } as UseSmileIDSampleDocument;
const picked = { ...smileIDSampleIdDetailsDefaults, country: kenya, document: passport };

/// A relinked partner may not enable what was picked for the last one.
describe('a relinked partner', () => {
  it('drops every pick when it lacks the country', () => {
    const kept = smileIDSampleIdDetailsWithEnabledOnly(picked, [{ code: 'NG', name: 'Nigeria' }], null);
    expect(kept.country).toBeNull();
    expect(kept.document).toBeNull();
  });

  it('keeps the country when it lacks only the document', () => {
    const nationalId = { ...passport, code: 'NATIONAL_ID', name: 'National ID', hasBack: true, format: 1 };
    const kept = smileIDSampleIdDetailsWithEnabledOnly(picked, [kenya], [nationalId]);
    expect(kept.country).toEqual(kenya);
    expect(kept.document).toBeNull();
  });

  it('keeps the picks, unchanged, while a list loads', () => {
    expect(smileIDSampleIdDetailsWithEnabledOnly(picked, null, null)).toBe(picked);
  });

  it('resumes straight into the SDK only on the same partner', () => {
    const expired = { productId: 'enhancedDocumentVerification', route: 'shell', resumeAt: 'flow' } as const;
    expect(smileIDSampleResumesInFlow(expired, 'p-1', 'p-1')).toBe(true);
    expect(smileIDSampleResumesInFlow(expired, 'p-1', 'p-2')).toBe(false);
    expect(smileIDSampleResumesInFlow(expired, null, 'p-1')).toBe(false);
    expect(smileIDSampleResumesInFlow({ ...expired, resumeAt: 'firstStep' }, 'p-1', 'p-1')).toBe(false);
  });

  it("carries the forms over only to the run's own partner while they hold its details", () => {
    const expired = { productId: 'enhancedDocumentVerification', route: 'shell', resumeAt: 'flow' } as const;
    const firstStep = { ...expired, resumeAt: 'firstStep' } as const;
    expect(smileIDSampleKeepsForms(expired, 'p-1', 'p-1', true)).toBe(true);
    expect(smileIDSampleKeepsForms(firstStep, 'p-1', 'p-1', true)).toBe(true);
    expect(smileIDSampleKeepsForms(firstStep, 'p-1', 'p-1', false)).toBe(false);
    expect(smileIDSampleKeepsForms(firstStep, 'p-1', 'p-2', true)).toBe(false);
    expect(smileIDSampleKeepsForms(firstStep, null, 'p-1', true)).toBe(false);
  });
});
