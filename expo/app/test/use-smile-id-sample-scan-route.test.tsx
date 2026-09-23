import {
  UseSmileIDSampleTestIds,
  UseSmileIDSampleThemeProvider,
  smileIDSampleTokenSession,
  useSmileIDSampleSessionStore,
} from '@smileid/sample-ui';
import { act, fireEvent, render, waitFor } from '@testing-library/react-native';
import type { ReactElement } from 'react';

import SdkFlowRun from '../app/flow/[productId]/run';
import ScanToken from '../app/token/scan';
import { smileIDSampleSimulatedToken } from '../src/flow/use-smile-id-sample-flow-tokens';
import { smileIDSampleLoadLaunchArgs, smileIDSampleResetLaunchArgs } from '../src/use-smile-id-sample-launch';

jest.mock('@smileid/usesmileid_mlkit_face', () => ({ useSmileIDMlkitFace: { key: 'mlkit' } }));
jest.mock('@smileid/usesmileid_vision_face', () => ({ useSmileIDVisionFace: { key: 'vision' } }));
/// The cold-start link, which carries the launch arguments on this platform.
let mockLaunchUrl: string | null = null;
jest.mock('expo-linking', () => ({ getInitialURL: jest.fn(async () => mockLaunchUrl) }));
jest.mock('expo-haptics', () => ({
  selectionAsync: jest.fn(async () => undefined),
  notificationAsync: jest.fn(async () => undefined),
  NotificationFeedbackType: { Success: 'success', Error: 'error' },
}));
/// What the clipboard holds for the Paste test; empty elsewhere.
let mockClipboard = '';
jest.mock('expo-clipboard', () => ({ getStringAsync: jest.fn(async () => mockClipboard) }));
jest.mock('expo-camera', () => ({ CameraView: () => null, useCameraPermissions: () => [null, jest.fn()] }));
jest.mock('react-native-safe-area-context', () => ({
  useSafeAreaInsets: () => ({ top: 44, bottom: 34, left: 0, right: 0 }),
}));

/// The redirect the route declared, which is how it leaves; recorded rather than navigated.
const mockRedirects: string[] = [];
const mockRouter = { back: jest.fn(), replace: jest.fn(), push: jest.fn(), canGoBack: () => true };
jest.mock('expo-router', () => ({
  useRouter: () => mockRouter,
  useIsFocused: () => true,
  useLocalSearchParams: () => ({ productId: 'enhancedKyc' }),
  Redirect: function Redirect({ href }: { href: string }) {
    mockRedirects.push(href);
    return null;
  },
}));
jest.mock('@smileid/usesmileid', () => ({
  ...jest.requireActual('@smileid/usesmileid'),
  UseSmileIDBuilder: () => null,
}));

const inTheme = async (element: ReactElement) => await render(<UseSmileIDSampleThemeProvider dark={false}>{element}</UseSmileIDSampleThemeProvider>);

const endedSession = () =>
  smileIDSampleTokenSession(
    smileIDSampleSimulatedToken({
      span: { id: 'ended', label: 'Expired', spanMillis: 900_000, ended: true },
      bindings: { consent: false, userDetails: false },
      environment: 'sandbox',
      nowMillis: Date.now(),
    }),
  )!;

beforeEach(() => {
  mockLaunchUrl = null;
  smileIDSampleResetLaunchArgs();
  useSmileIDSampleSessionStore.getState().reset();
  mockRedirects.length = 0;
  jest.clearAllMocks();
});

describe('the expiry gate', () => {
  it('sends a run whose session ended to the scanner, holding the run it interrupted', async () => {
    await act(async () => {
      await useSmileIDSampleSessionStore.getState().retire(endedSession());
    });
    await inTheme(<SdkFlowRun />);
    expect(mockRedirects).toEqual(['/token/scan']);
    expect(useSmileIDSampleSessionStore.getState().pendingRun).toEqual({ productId: 'enhancedKyc', route: 'fullscreen' });
  });

  // The root waits on the link before any route renders; the entry snapshot must then see it, not the defaults.
  it('takes its snapshot from the launch arguments the cold link carried', async () => {
    mockLaunchUrl = 'usesmileid-sample-expo:///flow/enhancedKyc/run?route=shell';
    await act(async () => {
      await smileIDSampleLoadLaunchArgs();
      await useSmileIDSampleSessionStore.getState().retire(endedSession());
    });
    await inTheme(<SdkFlowRun />);
    expect(useSmileIDSampleSessionStore.getState().pendingRun).toEqual({ productId: 'enhancedKyc', route: 'shell' });
  });

  it('lets a run with no session at all through to the SDK on the fixture path', async () => {
    await inTheme(<SdkFlowRun />);
    expect(mockRedirects).not.toContain('/token/scan');
  });
});

describe('the scanner', () => {
  it('says why it opened, drops the run from app state, and resumes it once a fresh session links', async () => {
    useSmileIDSampleSessionStore.getState().sendRun({ productId: 'enhancedKyc', route: 'fullscreen' });
    const screen = await inTheme(<ScanToken />);
    expect(screen.queryByText('Token session ended. Scan to continue where you left off.')).not.toBeNull();
    expect(useSmileIDSampleSessionStore.getState().pendingRun).toBeNull();

    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_SIMULATE));
    await waitFor(() => expect(mockRouter.replace).toHaveBeenCalledWith('/flow/enhancedKyc/run'));
    expect(mockRouter.back).not.toHaveBeenCalled();
  });

  it('opened deliberately, says nothing about an ended session and returns once linked', async () => {
    const screen = await inTheme(<ScanToken />);
    expect(screen.queryByText('Token session ended. Scan to continue where you left off.')).toBeNull();
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_SIMULATE));
    await waitFor(() => expect(useSmileIDSampleSessionStore.getState().live).not.toBeNull());
    expect(mockRouter.back).toHaveBeenCalledTimes(1);
    expect(mockRouter.replace).not.toHaveBeenCalled();
  });

  it('refuses a typed token that does not decode, under the field, and links nothing', async () => {
    const screen = await inTheme(<ScanToken />);
    await fireEvent.changeText(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_MANUAL_ENTRY), 'not-a-jwt');
    await fireEvent.press(screen.getByText('Link token'));
    expect(screen.queryByText('A token is three dot-separated base64url segments; this is not.')).not.toBeNull();
    expect(useSmileIDSampleSessionStore.getState().live).toBeNull();
  });

  it('pastes the clipboard into the field, and says so when it holds nothing', async () => {
    const screen = await inTheme(<ScanToken />);
    mockClipboard = '';
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_PASTE));
    await waitFor(() => expect(screen.queryByText('The clipboard holds no text to paste.')).not.toBeNull());
    mockClipboard = 'pasted.token.value';
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_PASTE));
    await waitFor(() => expect(screen.getByTestId(UseSmileIDSampleTestIds.TOKEN_MANUAL_ENTRY).props.value).toBe('pasted.token.value'));
    expect(screen.queryByText('Link token')).not.toBeNull();
  });
});
