import { smileIDSampleProducts, type UseSmileIDSampleProduct } from '@smileid/sample-ui';
import { UseSmileIDFlowBuilder } from '@smileid/usesmileid';

import {
  smileIDSampleApplying,
  smileIDSampleJourneyStepsFor,
  type UseSmileIDSampleFlowJourneyStep,
} from '../src/flow/use-smile-id-sample-flow-builder-config';
import type { UseSmileIDSampleFlowLaunchSnapshot } from '../src/flow/use-smile-id-sample-flow-launch-snapshot';
import { smileIDSamplePreflight } from '../src/flow/use-smile-id-sample-flow-preflight';

// Each provider resolves its native module on import, which no jest runtime has. Mocked rather than
// avoided, because the host requiring exactly one of them is the thing under test.
jest.mock('@smileid/usesmileid_mlkit_face', () => ({ useSmileIDMlkitFace: { key: 'mlkit' } }));
jest.mock('@smileid/usesmileid_vision_face', () => ({ useSmileIDVisionFace: { key: 'vision' } }));

const productFor = (id: string): UseSmileIDSampleProduct =>
  smileIDSampleProducts.find((product) => product.id === id)!;

const snapshot = (
  overrides: Partial<UseSmileIDSampleFlowLaunchSnapshot> = {},
): UseSmileIDSampleFlowLaunchSnapshot => ({
  product: productFor('smartSelfieEnrollment'),
  route: 'fullscreen',
  userDetails: {
    firstName: 'Ada',
    lastName: 'Okafor',
    email: 'ada.okafor@example.com',
    phone: '',
  },
  idDetails: { country: null, idType: null, idNumber: '' },
  scenario: 'normal',
  theme: 'brandDefault',
  sandbox: true,
  allowAgentMode: false,
  enableEnhancedLiveness: true,
  consentStep: true,
  instructionsStep: true,
  previewStep: true,
  userId: 'user_1',
  partnerId: 'p-1',
  partnerName: 'Kobo Bank',
  callbackUrl: '',
  ...overrides,
});

const built = (value: UseSmileIDSampleFlowLaunchSnapshot) => {
  const builder = new UseSmileIDFlowBuilder();
  smileIDSampleApplying(builder, value);
  return builder;
};

describe('the journey the switches compose', () => {
  it('is consent, instructions, capture, preview and processing for a selfie enrollment', () => {
    expect(smileIDSampleJourneyStepsFor(snapshot())).toEqual<UseSmileIDSampleFlowJourneyStep[]>([
      'consent',
      'instructions',
      'selfieCapture',
      'preview',
      'processing',
    ]);
  });

  it('takes each step out with its own switch', () => {
    expect(
      smileIDSampleJourneyStepsFor(
        snapshot({ consentStep: false, instructionsStep: false, previewStep: false }),
      ),
    ).toEqual<UseSmileIDSampleFlowJourneyStep[]>(['selfieCapture', 'processing']);
  });

  // The one journey without capture, per its own validator.
  it('is consent and processing only for enhanced KYC', () => {
    expect(
      smileIDSampleJourneyStepsFor(snapshot({ product: productFor('enhancedKyc') })),
    ).toEqual<UseSmileIDSampleFlowJourneyStep[]>(['consent', 'processing']);
  });

  it('puts the document products captures in opposite orders', () => {
    const plain = { consentStep: false, instructionsStep: false, previewStep: false };
    expect(
      smileIDSampleJourneyStepsFor(
        snapshot({ product: productFor('documentVerification'), ...plain }),
      ),
    ).toEqual<UseSmileIDSampleFlowJourneyStep[]>([
      'documentCapture',
      'selfieCapture',
      'processing',
    ]);
    expect(
      smileIDSampleJourneyStepsFor(
        snapshot({ product: productFor('enhancedDocumentVerification'), ...plain }),
      ),
    ).toEqual<UseSmileIDSampleFlowJourneyStep[]>([
      'selfieCapture',
      'documentCapture',
      'processing',
    ]);
  });
});

describe('the gate', () => {
  it('passes a complete selfie enrollment', () => {
    expect(smileIDSamplePreflight(snapshot()).kind).toBe('ready');
  });

  // The SDK requires a contact field even though the form labels both optional.
  it('sends an empty form back to the form rather than to the SDK', () => {
    const outcome = smileIDSamplePreflight(
      snapshot({ userDetails: { firstName: '', lastName: '', email: '', phone: '' } }),
    );
    expect(outcome.kind).toBe('needsDetails');
  });

  it('names the fields an empty form left for the form to fix', () => {
    const outcome = smileIDSamplePreflight(
      snapshot({ userDetails: { firstName: '', lastName: '', email: '', phone: '' } }),
    );
    const reported =
      outcome.kind === 'ready' ? '' : outcome.issues.map((issue) => issue.message).join('; ');
    expect(reported).toContain('givenNames');
    expect(reported).toContain('lastName');
  });
});

describe('what the SDK is handed', () => {
  it('the user details the form collected, with an absent field left absent', () => {
    const details = built(snapshot()).userDetails!;
    expect(details.givenNames).toBe('Ada');
    expect(details.email).toBe('ada.okafor@example.com');
    expect(details.phoneNumber).toBeUndefined();
  });

  // Only authentication carries one: the server issues the id for every other job.
  it('a user id only where the job type requires one', () => {
    expect(built(snapshot({ product: productFor('smartSelfieAuth') })).userId).toBe('user_1');
    expect(built(snapshot()).userId).toBeUndefined();
  });

  // The gate can only call `validate()`, which the SDK documents as far weaker than its build: a
  // missing consent icon passes one and fails the other, and a rejected build renders nothing.
  it('every product builds a configuration the SDK accepts', () => {
    for (const product of smileIDSampleProducts) {
      const result = built(
        snapshot({
          product,
          idDetails: {
            country: { code: 'KE', label: 'Kenya', flag: '🇰🇪' },
            idType: { id: 'NATIONAL_ID', label: 'National ID', countries: ['KE'] },
            idNumber: '11111111',
          },
        }),
      ).build();

      expect(result.kind).toBe('success');
    }
  });

  // The regression check for the defect that took the whole JS bundle down on Android: naming the
  // other platform's provider resolves its native module at import time.
  it('requires only the platform whose analyzer it asks for', () => {
    jest.isolateModules(() => {
      const vision = jest.requireMock('@smileid/usesmileid_vision_face');
      expect(vision).toBeDefined();
    });
    expect(() => built(snapshot())).not.toThrow();
  });
});
