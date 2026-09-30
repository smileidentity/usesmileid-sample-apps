import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import {
  UseSmileIDSampleCaptureAs,
  smileIDSampleCatalogueDocuments,
  smileIDSampleDecodeDocuments,
  smileIDSampleIdDetailsDefaults,
  smileIDSampleProducts,
  type UseSmileIDSampleProduct,
} from '@smileid/sample-ui';
import { UseSmileIDFlowBuilder } from '@smileid/usesmileid';

import {
  smileIDSampleApplying,
  smileIDSampleCapturesBothSides,
  smileIDSampleJourneyStepsFor,
  type UseSmileIDSampleFlowJourneyStep,
} from '../src/flow/use-smile-id-sample-flow-builder-config';
import type { UseSmileIDSampleFlowLaunchSnapshot } from '../src/flow/use-smile-id-sample-flow-launch-snapshot';
import { smileIDSamplePreflight } from '../src/flow/use-smile-id-sample-flow-preflight';

// Mocked, not avoided: the host requiring exactly one provider is the thing under test.
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
  idDetails: smileIDSampleIdDetailsDefaults,
  scenario: 'normal',
  theme: 'brandDefault',
  sandbox: true,
  allowAgentMode: false,
  enableEnhancedLiveness: true,
  consentStep: true,
  instructionsStep: true,
  previewStep: true,
  captureMode: 'autoWithFallback',
  galleryUpload: false,
  captureBothSides: true,
  allowSkipBack: false,
  selfieFirst: false,
  userId: 'user_1',
  partnerId: 'p-1',
  partnerName: 'Kobo Bank',
  callbackUrl: '',
  session: null,
  sessionExpired: false,
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

  it('captures the document first for every document product unless selfie first is on', () => {
    const plain = { consentStep: false, instructionsStep: false, previewStep: false };
    for (const id of ['documentVerification', 'enhancedDocumentVerification', 'residencyDocumentVerification']) {
      expect(smileIDSampleJourneyStepsFor(snapshot({ product: productFor(id), ...plain }))).toEqual<
        UseSmileIDSampleFlowJourneyStep[]
      >(['documentCapture', 'selfieCapture', 'processing']);
      expect(
        smileIDSampleJourneyStepsFor(snapshot({ product: productFor(id), ...plain, selfieFirst: true })),
      ).toEqual<UseSmileIDSampleFlowJourneyStep[]>(['selfieCapture', 'documentCapture', 'processing']);
    }
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
      outcome.kind === 'ready' || outcome.kind === 'needsSession' ? '' : outcome.issues.map((issue) => issue.message).join('; ');
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

  // `validate()` is weaker than the build: a missing consent icon passes one and fails the other.
  it('every product builds a configuration the SDK accepts', () => {
    for (const product of smileIDSampleProducts) {
      const result = built(
        snapshot({
          product,
          idDetails: {
            ...smileIDSampleIdDetailsDefaults,
            country: { code: 'KE', name: 'Kenya' },
            idType: { id: 'NATIONAL_ID', type: 'NATIONAL_ID', label: 'National ID', regex: '^[0-9]{1,9}$' },
            // Both families filled, so each product finds the field it submits.
            document: { code: 'PASSPORT', subType: null, name: 'Passport', hasBack: false, format: 3 },
            idNumber: '11111111',
          },
        }),
      ).build();

      expect(result.kind).toBe('success');
    }
  });

  it('every document setting builds, except the Green Book the SDK refuses on Enhanced Document Verification', () => {
    for (const id of ['documentVerification', 'enhancedDocumentVerification']) {
      for (const captureAs of [null, ...Object.values(UseSmileIDSampleCaptureAs)]) {
        for (const flag of [true, false]) {
          const result = built(
            snapshot({
              product: productFor(id),
              idDetails: {
                ...smileIDSampleIdDetailsDefaults,
                country: { code: 'ZA', name: 'South Africa' },
                document: { code: 'IDENTITY_CARD', subType: null, name: 'Identity Card', hasBack: true, format: 1 },
                captureAsOverride: captureAs,
              },
              captureBothSides: flag,
              allowSkipBack: !flag,
              selfieFirst: flag,
            }),
          ).build();
          const refused = id === 'enhancedDocumentVerification' && captureAs === UseSmileIDSampleCaptureAs.GreenBook;
          expect([id, captureAs, flag, result.kind]).toEqual([id, captureAs, flag, refused ? 'invalid' : 'success']);
        }
      }
    }
  });

  it('residency builds as both sides of a passport, whatever the form or settings hold', () => {
    const builder = built(
      snapshot({
        product: productFor('residencyDocumentVerification'),
        idDetails: {
          ...smileIDSampleIdDetailsDefaults,
          country: { code: 'NG', name: 'Nigeria' },
          document: { code: 'IDENTITY_CARD', subType: null, name: 'National ID', hasBack: true, format: 1 },
          captureAsOverride: UseSmileIDSampleCaptureAs.GenericDocument,
        },
        captureBothSides: false,
        allowSkipBack: true,
      }),
    );
    expect(
      smileIDSampleCapturesBothSides(
        snapshot({ product: productFor('residencyDocumentVerification'), captureBothSides: false }),
      ),
    ).toBe(true);
    expect(builder.residencyDocumentVerificationParams).toEqual({ country: 'NG', idType: 'PASSPORT' });
    expect(builder.documentVerificationParams).toBeUndefined();
    expect(builder.build().kind).toBe('success');
  });

  it('a passport is captured front only, whatever the setting', () => {
    for (const captureAs of Object.values(UseSmileIDSampleCaptureAs)) {
      for (const setting of [true, false]) {
        const captured = smileIDSampleCapturesBothSides(
          snapshot({ idDetails: { ...smileIDSampleIdDetailsDefaults, captureAsOverride: captureAs }, captureBothSides: setting }),
        );
        expect([captureAs, setting, captured]).toEqual([
          captureAs,
          setting,
          setting && captureAs !== UseSmileIDSampleCaptureAs.Passport,
        ]);
      }
    }
  });

  // The regression check for the import that took the whole JS bundle down on Android.
  it('requires only the platform whose analyzer it asks for', () => {
    jest.isolateModules(() => {
      const vision = jest.requireMock('@smileid/usesmileid_vision_face');
      expect(vision).toBeDefined();
    });
    expect(() => built(snapshot())).not.toThrow();
  });
});

describe('the ID parameters', () => {
  const kenya = { code: 'KE', name: 'Kenya' };
  const nationalId = { id: 'NATIONAL_ID', type: 'NATIONAL_ID', label: 'National ID', regex: '^[0-9]{1,9}$' };

  it('sends a document job the document, even with an ID type left in the form', () => {
    const value = snapshot({
      product: productFor('documentVerification'),
      idDetails: {
        ...smileIDSampleIdDetailsDefaults,
        country: kenya,
        idType: nationalId,
        document: { code: 'PASSPORT', subType: null, name: 'Passport', hasBack: false, format: 3 },
      },
    });
    expect(built(value).documentVerificationParams?.idType).toBe('PASSPORT');
  });

  it('sends a KYC job the number trimmed, as the form checked it', () => {
    const value = snapshot({
      product: productFor('biometricKyc'),
      idDetails: { ...smileIDSampleIdDetailsDefaults, country: kenya, idType: nationalId, idNumber: ' 12345678 ' },
    });
    expect(built(value).biometricKYCParams?.idNumber).toBe('12345678');
  });
});

/// Match document on every fixture row of both document products, through the SDK's `build()` and its job-type rules.
describe('Match document', () => {
  const fixture = JSON.parse(readFileSync(join(__dirname, '..', 'assets', 'catalogue-fixture.json'), 'utf8')) as {
    supported_documents: unknown;
  };
  const documents = smileIDSampleDecodeDocuments(JSON.stringify(fixture.supported_documents))!;

  it('never builds a pair the SDK refuses', () => {
    let checked = 0;
    for (const id of ['documentVerification', 'enhancedDocumentVerification']) {
      for (const listed of documents) {
        for (const document of smileIDSampleCatalogueDocuments(documents, listed.country.code, id)) {
          const result = built(
            snapshot({
              product: productFor(id),
              idDetails: { ...smileIDSampleIdDetailsDefaults, country: listed.country, document },
            }),
          ).build();
          expect([id, document.code, document.subType, result.kind]).toEqual([id, document.code, document.subType, 'success']);
          checked++;
        }
      }
    }
    expect(checked).toBeGreaterThan(0);
  });
});
