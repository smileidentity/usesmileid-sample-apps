import {
  smileIDSampleBase64UrlEncode,
  smileIDSampleProducts,
  smileIDSampleSimulatedSpans,
  smileIDSampleTokenSession,
  type UseSmileIDSampleProduct,
  type UseSmileIDSampleTokenSession,
} from '@smileid/sample-ui';
import { UseSmileIDFlowBuilder, decodeSmileIDToken } from '@smileid/usesmileid';

import {
  smileIDSampleApplying,
  smileIDSampleJourneyStepsFor,
} from '../src/flow/use-smile-id-sample-flow-builder-config';
import { smileIDSampleFirstStepFor, smileIDSampleStepAfterUserDetails } from '../src/flow/use-smile-id-sample-flow-journey';
import type { UseSmileIDSampleFlowLaunchSnapshot } from '../src/flow/use-smile-id-sample-flow-launch-snapshot';
import { smileIDSamplePreflight } from '../src/flow/use-smile-id-sample-flow-preflight';
import { smileIDSampleSimulatedToken } from '../src/flow/use-smile-id-sample-flow-tokens';
import { smileIDSampleStatusOutcome, smileIDSampleStatusUrl } from '../src/status/use-smile-id-sample-status-api';

jest.mock('@smileid/usesmileid_mlkit_face', () => ({ useSmileIDMlkitFace: { key: 'mlkit' } }));
jest.mock('@smileid/usesmileid_vision_face', () => ({ useSmileIDVisionFace: { key: 'vision' } }));

const productFor = (id: string): UseSmileIDSampleProduct => smileIDSampleProducts.find((product) => product.id === id)!;
const span = (id: string) => smileIDSampleSimulatedSpans.find((candidate) => candidate.id === id)!;

const minted = ({
  consent = false,
  userDetails = false,
  environment = 'sandbox' as 'sandbox' | 'production',
  spanId = 'fifteenMinutes',
} = {}): UseSmileIDSampleTokenSession =>
  smileIDSampleTokenSession(
    smileIDSampleSimulatedToken({
      span: span(spanId),
      bindings: { consent, userDetails },
      environment,
      nowMillis: Date.now(),
    }),
  )!;

const snapshot = (overrides: Partial<UseSmileIDSampleFlowLaunchSnapshot> = {}): UseSmileIDSampleFlowLaunchSnapshot => ({
  product: productFor('enhancedKyc'),
  route: 'fullscreen',
  userDetails: { firstName: 'Ada', lastName: 'Okafor', email: 'ada.okafor@example.com', phone: '' },
  idDetails: {
    country: { code: 'KE', label: 'Kenya', flag: '🇰🇪' },
    idType: { id: 'NATIONAL_ID', label: 'National ID', countries: ['KE'] },
    idNumber: '11111111',
  },
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
  callbackUrl: 'https://partner.example.com/hook',
  session: null,
  sessionExpired: false,
  ...overrides,
});

const built = (value: UseSmileIDSampleFlowLaunchSnapshot) => {
  const builder = new UseSmileIDFlowBuilder();
  smileIDSampleApplying(builder, value);
  return builder;
};

type NetworkBlock = {
  config?: {
    token?: string;
    onTokenExpired?: (previous: string) => Promise<string>;
    partnerConfig?: { partnerId: string; callbackUrl: string; useSandbox: boolean };
  };
};

const networkOf = (value: UseSmileIDSampleFlowLaunchSnapshot): NetworkBlock['config'] => {
  const result = built(value).build();
  if (result.kind !== 'success') throw new Error(`the flow did not build: ${JSON.stringify(result)}`);
  return (result.configuration.network as NetworkBlock | undefined)?.config;
};

describe('the simulated scan', () => {
  it('mints a token the decoder reads back with the chosen span, environment and bindings', () => {
    const session = minted({ consent: true, userDetails: true, environment: 'production', spanId: 'eightHours' });
    expect(session.expiresAtMillis - session.issuedAtMillis).toBe(8 * 3_600_000);
    expect(session.environment).toBe('production');
    expect(session.bindings.consent?.granted).toBe(true);
    expect(session.bindings.givenNames).toBe(true);
    expect(session.bindings.idNumberReference).toBe('vault_id_number');
  });

  it('mints the Expired span wholly in the past, the only way to reach the expiry gate', () => {
    expect(minted({ spanId: 'ended' }).expiresAtMillis).toBeLessThan(Date.now());
  });

  it('binds nothing unless asked, so a simulated session never silently changes the screen set', () => {
    expect(minted().bindings).toEqual({});
  });
});

describe('the decoder, pinned to the SDK rather than to our reading of it', () => {
  it.each([
    { consent: false, userDetails: false },
    { consent: true, userDetails: false },
    { consent: false, userDetails: true },
    { consent: true, userDetails: true },
  ])('agrees on every presence flag the SDK models, %o', (bindings) => {
    const token = smileIDSampleSimulatedToken({ span: span('oneHour'), bindings, environment: 'sandbox', nowMillis: Date.now() });
    const ours = smileIDSampleTokenSession(token)!.bindings;
    const sdk = decodeSmileIDToken(token)?.tokenPayload;
    expect(ours.givenNames === true).toBe(sdk?.hasGivenNames === true);
    expect(ours.lastName === true).toBe(sdk?.hasLastName === true);
    expect(ours.email === true).toBe(sdk?.hasEmail === true);
    expect(ours.phoneNumber === true).toBe(sdk?.hasPhoneNumber === true);
    expect(ours.consent != null).toBe(sdk?.consent !== undefined);
  });
});

describe('what the SDK is handed under a session', () => {
  it('the scanned token, its partner and its environment, and no profile callback', () => {
    const session = minted({ environment: 'production' });
    const network = networkOf(snapshot({ session, sandbox: false }));
    expect(network?.token).toBe(session.token);
    expect(network?.partnerConfig?.useSandbox).toBe(false);
    expect(network?.partnerConfig?.callbackUrl).toBe('');
  });

  it('the partner the token was minted for, over the local profile', () => {
    const now = Math.floor(Date.now() / 1000);
    const token = [
      '{"alg":"none"}',
      `{"iat":${now},"exp":${now + 900},"api_url":"https://testapi.smileidentity.com/v3","partner_id":"p_token"}`,
      's',
    ]
      .map(smileIDSampleBase64UrlEncode)
      .join('.');
    expect(networkOf(snapshot({ session: smileIDSampleTokenSession(token) }))?.partnerConfig?.partnerId).toBe('p_token');
    expect(networkOf(snapshot())?.partnerConfig?.partnerId).toBe('p-1');
  });

  it('hands the scanned token back on expiry, since nothing here may mint a replacement', async () => {
    const session = minted();
    await expect(networkOf(snapshot({ session }))?.onTokenExpired?.('previous')).resolves.toBe(session.token);
  });

  it('keeps the fixture token for the two scenarios that are about refresh', () => {
    const session = minted();
    expect(networkOf(snapshot({ session, scenario: 'badRefresh' }))?.token).not.toBe(session.token);
  });

  it('omits the consent screen once the token binds consent, and keeps it otherwise', () => {
    expect(smileIDSampleJourneyStepsFor(snapshot({ session: minted({ consent: true }) }))).toEqual(['processing']);
    expect(smileIDSampleJourneyStepsFor(snapshot({ session: minted() }))).toEqual(['consent', 'processing']);
  });

  it('passes no user details at all when the token binds them, never blanks', () => {
    const session = minted({ userDetails: true });
    const value = snapshot({ session, userDetails: { firstName: '', lastName: '', email: '', phone: '' } });
    expect(built(value).userDetails).toBeUndefined();
  });

  it('takes the ID parameters from the token first, the ID number as its reference', () => {
    const session = minted({ userDetails: true });
    const value = snapshot({ session, idDetails: { country: null, idType: null, idNumber: '' } });
    expect(built(value).enhancedKYCParams).toEqual({ country: 'KE', idType: 'NATIONAL_ID', idNumber: 'vault_id_number' });
  });

  it('builds a configuration the SDK accepts for every product under every binding', () => {
    for (const product of smileIDSampleProducts) {
      for (const bindings of [
        { consent: false, userDetails: false },
        { consent: true, userDetails: false },
        { consent: false, userDetails: true },
        { consent: true, userDetails: true },
      ]) {
        const result = built(snapshot({ product, session: minted(bindings) })).build();
        expect({ product: product.id, ...bindings, kind: result.kind }).toEqual({
          product: product.id,
          ...bindings,
          kind: 'success',
        });
      }
    }
  });
});

describe('the gate under a session', () => {
  it('sends a run whose session ran out back to the scanner, ahead of any form', () => {
    const outcome = smileIDSamplePreflight(
      snapshot({ sessionExpired: true, userDetails: { firstName: '', lastName: '', email: '', phone: '' } }),
    );
    expect(outcome.kind).toBe('needsSession');
  });

  it('does not send a bound run to a form the SDK no longer needs', () => {
    const value = snapshot({
      session: minted({ userDetails: true }),
      userDetails: { firstName: '', lastName: '', email: '', phone: '' },
      idDetails: { country: null, idType: null, idNumber: '' },
    });
    expect(smileIDSamplePreflight(value).kind).toBe('ready');
  });
});

describe('the journey', () => {
  it('skips both forms when the token binds everything they would collect', () => {
    const bindings = minted({ userDetails: true }).bindings;
    expect(smileIDSampleFirstStepFor(productFor('biometricKyc'), bindings)).toBe('/flow/biometricKyc/run');
    expect(smileIDSampleFirstStepFor(productFor('enhancedDocumentVerification'), bindings)).toBe(
      '/flow/enhancedDocumentVerification/run',
    );
  });

  it('keeps both forms with no token', () => {
    expect(smileIDSampleFirstStepFor(productFor('biometricKyc'), null)).toBe('/flow/biometricKyc/details');
    expect(smileIDSampleStepAfterUserDetails(productFor('biometricKyc'), null)).toBe('/flow/biometricKyc/id-details');
    expect(smileIDSampleStepAfterUserDetails(productFor('smartSelfieEnrollment'), null)).toBe(
      '/flow/smartSelfieEnrollment/run',
    );
  });

  it('shows the form on a partial binding rather than skipping it', () => {
    expect(smileIDSampleFirstStepFor(productFor('biometricKyc'), { givenNames: true, lastName: true })).toBe(
      '/flow/biometricKyc/details',
    );
  });
});

describe('the status call', () => {
  it('asks the row environment host with the job id as one path segment', () => {
    expect(smileIDSampleStatusUrl('job/1?x', true)).toBe('https://testapi.smileidentity.com/v3/status/job%2F1%3Fx');
    expect(smileIDSampleStatusUrl('job_1', false)).toBe('https://api.smileidentity.com/v3/status/job_1');
  });

  it('maps five API states onto the four badges', () => {
    const body = (status: string) => ({ status, message: 'm', job_id: 'j', user_id: 'u', created_at: 'c' });
    expect(smileIDSampleStatusOutcome(200, body('clear'))).toMatchObject({ kind: 'updated', status: 'Clear' });
    expect(smileIDSampleStatusOutcome(200, body('attention'))).toMatchObject({ status: 'Attention' });
    expect(smileIDSampleStatusOutcome(200, body('block'))).toMatchObject({ status: 'Blocked' });
    expect(smileIDSampleStatusOutcome(200, body('error'))).toMatchObject({ status: 'Blocked' });
    expect(smileIDSampleStatusOutcome(200, body('processing'))).toEqual({ kind: 'stillProcessing' });
    expect(smileIDSampleStatusOutcome(200, body('weird'))).toEqual({ kind: 'failed', reason: "Unrecognised status 'weird'" });
    expect(smileIDSampleStatusOutcome(401, body('clear'))).toEqual({ kind: 'failed', reason: 'HTTP 401' });
    expect(smileIDSampleStatusOutcome(200, null)).toEqual({ kind: 'failed', reason: 'HTTP 200' });
  });
});
