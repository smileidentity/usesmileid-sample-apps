import {
  UseSmileIDSampleTestIds,
  UseSmileIDSampleThemeProvider,
  smileIDSampleBase64UrlEncode,
  smileIDSampleLaunchArgDefaults,
  smileIDSampleTokenSession,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleRunIntent,
} from '@smileid/sample-ui';
import { NjiaDefaults } from '@smileid/njia';
import { act, fireEvent, render, waitFor } from '@testing-library/react-native';

import { smileIDSampleSimulatedToken } from '../src/flow/use-smile-id-sample-flow-tokens';
import { smileIDSampleStartShell, UseSmileIDSampleShell } from '../src/navigation/use-smile-id-sample-shell';
import { smileIDSampleResetLaunchArgs } from '../src/use-smile-id-sample-launch';
import {
  smileIDSampleReferenceNavigation,
  smileIDSampleStackKinds,
  smileIDSampleTopKind,
} from './support/use-smile-id-sample-test-njia';

jest.mock('@smileid/usesmileid_mlkit_face', () => ({ useSmileIDMlkitFace: { key: 'mlkit' } }));
jest.mock('@smileid/usesmileid_vision_face', () => ({ useSmileIDVisionFace: { key: 'vision' } }));
jest.mock('@smileid/usesmileid_mlkit_document', () => ({ useSmileIDMlkitDocument: { key: 'mlkit-document' } }));
jest.mock('@smileid/usesmileid_vision_document', () => ({ useSmileIDVisionDocument: { key: 'vision-document' } }));
jest.mock('expo-linking', () => ({
  getInitialURL: jest.fn(async () => null),
  addEventListener: () => ({ remove: () => undefined }),
}));
jest.mock('expo-haptics', () => ({
  notificationAsync: jest.fn(async () => undefined),
  NotificationFeedbackType: { Success: 'success', Error: 'error' },
}));
/// The clipboard's text.
let mockClipboard = '';
jest.mock('expo-clipboard', () => ({ getStringAsync: jest.fn(async () => mockClipboard) }));
jest.mock('expo-camera', () => ({ CameraView: () => null, useCameraPermissions: () => [null, jest.fn()] }));
jest.mock('react-native-safe-area-context', () => ({
  useSafeAreaInsets: () => ({ top: 44, bottom: 34, left: 0, right: 0 }),
}));
jest.mock('@smileid/usesmileid', () => ({
  ...jest.requireActual('@smileid/usesmileid'),
  UseSmileIDBuilder: () => null,
}));

/// The real shell on njia's reference reducer, launched at the app's link to `path` when given, else from the icon.
const shellAt = async (path?: string) => {
  const { model } = smileIDSampleReferenceNavigation();
  smileIDSampleStartShell(path === undefined ? null : `usesmileid-sample-expo://${path}`, smileIDSampleLaunchArgDefaults);
  const screen = await render(
    <UseSmileIDSampleThemeProvider dark={false}>
      <UseSmileIDSampleShell args={smileIDSampleLaunchArgDefaults} />
    </UseSmileIDSampleThemeProvider>,
  );
  // The scanner takes taps once its step has moved in.
  await act(async () => await new Promise((resolve) => setTimeout(resolve, NjiaDefaults.motionDurationMs + 50)));
  return { screen, engine: () => model.engine! };
};

/// A details-bound session lasting `spanMillis`.
const shortSession = (spanMillis: number) => {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const claims = `{"iat":${nowSeconds - 1},"exp":${Math.ceil((Date.now() + spanMillis) / 1000)},"api_url":"https://testapi.smileidentity.com/v3","payload":{"given_names":"v","last_name":"v","email":"v","country":"KE","id_type":"NATIONAL_ID","id_number":"v"}}`;
  return smileIDSampleTokenSession(['{"alg":"none"}', claims, 's'].map(smileIDSampleBase64UrlEncode).join('.'))!;
};

const lapse = (session: { expiresAtMillis: number }) =>
  new Promise((resolve) => setTimeout(resolve, session.expiresAtMillis - Date.now() + 20));

const endedSession = () =>
  smileIDSampleTokenSession(
    smileIDSampleSimulatedToken({
      span: { id: 'ended', label: 'Expired', spanMillis: 900_000, ended: true },
      bindings: { consent: false, userDetails: false },
      environment: 'sandbox',
      nowMillis: Date.now(),
    }),
  )!;

/// The runs handed to the scanner, which claims each as it mounts, so the store alone can't show them.
let sent: UseSmileIDSampleRunIntent[] = [];
let unsubscribe = () => {};

beforeEach(() => {
  smileIDSampleResetLaunchArgs();
  useSmileIDSampleSessionStore.getState().reset();
  jest.clearAllMocks();
  sent = [];
  unsubscribe = useSmileIDSampleSessionStore.subscribe((state, previous) => {
    if (state.pendingRun !== null && state.pendingRun !== previous.pendingRun) sent.push(state.pendingRun);
  });
});

afterEach(() => unsubscribe());

describe('the expiry gate', () => {
  it('sends a run whose session ended to the scanner in its place, holding the run it interrupted', async () => {
    await act(async () => {
      const ended = endedSession();
      await useSmileIDSampleSessionStore.getState().link(ended);
      await useSmileIDSampleSessionStore.getState().retire(ended);
    });
    const { engine } = await shellAt('flow/enhancedKyc/run');
    await waitFor(() => expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'scanToken']));
    expect(sent.at(-1)).toEqual({ productId: 'enhancedKyc', route: 'fullscreen', resumeAt: 'flow' });
  });

  it('takes the route it holds from the link, which opened the in-shell run', async () => {
    const { engine } = await shellAt('flow/enhancedKyc/run?route=shell');
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('scanToken'));
    expect(sent.at(-1)).toEqual({ productId: 'enhancedKyc', route: 'shell', resumeAt: 'flow' });
  });

  it('reads the clock at entry, so a session that lapsed since the last tick is sent to the scanner', async () => {
    const session = shortSession(300);
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(session);
    });
    await lapse(session);
    const { engine } = await shellAt('flow/enhancedKyc/run');
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('scanToken'));
  });

  it('reads the clock at the tap, so a session that lapsed since the last tick opens the scanner', async () => {
    const session = shortSession(300);
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(session);
    });
    const { screen, engine } = await shellAt();
    await lapse(session);
    await fireEvent.press(screen.getByTestId('sample_product_card_biometricKyc'));
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'scanToken']);
    expect(sent.at(-1)).toEqual({ productId: 'biometricKyc', route: 'fullscreen', resumeAt: 'firstStep' });
  });

  it('starts a live tap at its first form, under the run facts its product needs', async () => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().link(shortSession(600_000));
    });
    const { screen, engine } = await shellAt();
    await fireEvent.press(screen.getByTestId('sample_product_card_smartSelfieAuth'));
    // The token binds the user's details, so the consent form is skipped and Auth asks for the user ID.
    expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'authUserId']);
    expect([...engine().state.facts].sort()).toEqual(['fullScreenRun', 'needsUserId']);
  });

  it('sends a run with no session at all to the scanner rather than the SDK', async () => {
    const { engine } = await shellAt('flow/enhancedKyc/run');
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('scanToken'));
  });
});

describe('the scanner', () => {
  it('says why it opened, drops the run from app state, and resumes a run of unknown partner at its first step', async () => {
    useSmileIDSampleSessionStore.getState().sendRun({ productId: 'enhancedKyc', route: 'fullscreen', resumeAt: 'flow' });
    const { screen, engine } = await shellAt('token/scan');
    expect(screen.queryByText('Scan a token to start this verification.')).not.toBeNull();
    expect(useSmileIDSampleSessionStore.getState().pendingRun).toBeNull();

    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_SIMULATE));
    // In the scanner's place, so back from the form goes to Products, not to a scanner already used.
    await waitFor(() => expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'consentDetailsForm']));
    expect(engine().state.entries.at(-1)?.arg).toBe('enhancedKyc');
  });

  it('resumes a run sent from a product tap at its first step', async () => {
    useSmileIDSampleSessionStore
      .getState()
      .sendRun({ productId: 'smartSelfieEnrollment', route: 'fullscreen', resumeAt: 'firstStep' });
    const { screen, engine } = await shellAt('token/scan');
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_SIMULATE));
    await waitFor(() => expect(smileIDSampleStackKinds(engine())).toEqual(['products', 'consentDetailsForm']));
  });

  it('opened deliberately, says nothing about an ended session and returns once linked', async () => {
    const { screen, engine } = await shellAt('token/scan');
    expect(screen.queryByText('Token session ended. Scan to continue where you left off.')).toBeNull();
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_SIMULATE));
    await waitFor(() => expect(useSmileIDSampleSessionStore.getState().live).not.toBeNull());
    expect(smileIDSampleStackKinds(engine())).toEqual(['products']);
  });

  it('refuses a typed token that does not decode, under the field, and links nothing', async () => {
    const { screen } = await shellAt('token/scan');
    await fireEvent.changeText(screen.getByPlaceholderText('Or enter token manually'), 'not-a-jwt');
    await fireEvent.press(screen.getByText('Link token'));
    expect(screen.queryByText('A token is three dot-separated base64url segments; this is not.')).not.toBeNull();
    expect(useSmileIDSampleSessionStore.getState().live).toBeNull();
  });

  it('pastes the clipboard into the field, and says so when it holds nothing', async () => {
    const { screen } = await shellAt('token/scan');
    mockClipboard = '';
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_PASTE));
    await waitFor(() => expect(screen.queryByText('The clipboard holds no text to paste.')).not.toBeNull());
    mockClipboard = 'pasted.token.value';
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_PASTE));
    await waitFor(() => expect(screen.getByPlaceholderText('Or enter token manually').props.value).toBe('pasted.token.value'));
    expect(screen.queryByText('Link token')).not.toBeNull();
    expect(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_MANUAL_ENTRY)).toContainElement(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_PASTE));
  });
});
