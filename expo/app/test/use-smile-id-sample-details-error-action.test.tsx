import {
  UseSmileIDSampleTestIds,
  UseSmileIDSampleThemeProvider,
  smileIDSampleErrorSubmissionFallback,
  smileIDSampleLaunchArgDefaults,
  useSmileIDSampleResultStore,
  useSmileIDSampleSessionStore,
} from '@smileid/sample-ui';
import { NjiaDefaults } from '@smileid/njia';
import { act, fireEvent, render, waitFor } from '@testing-library/react-native';

import { smileIDSampleStartShell, UseSmileIDSampleShell } from '../src/navigation/use-smile-id-sample-shell';
import { smileIDSampleResetLaunchArgs } from '../src/use-smile-id-sample-launch';
import { smileIDSampleReferenceNavigation, smileIDSampleTopKind } from './support/use-smile-id-sample-test-njia';

jest.mock('@smileid/usesmileid_mlkit_face', () => ({ useSmileIDMlkitFace: { key: 'mlkit' } }));
jest.mock('@smileid/usesmileid_vision_face', () => ({ useSmileIDVisionFace: { key: 'vision' } }));
jest.mock('@smileid/usesmileid_mlkit_document', () => ({ useSmileIDMlkitDocument: { key: 'mlkit-document' } }));
jest.mock('@smileid/usesmileid_vision_document', () => ({ useSmileIDVisionDocument: { key: 'vision-document' } }));
jest.mock('expo-linking', () => ({
  getInitialURL: jest.fn(async () => null),
  addEventListener: () => ({ remove: () => undefined }),
}));
jest.mock('expo-camera', () => ({ CameraView: () => null, useCameraPermissions: () => [null, jest.fn()] }));
jest.mock('react-native-safe-area-context', () => ({
  ...jest.requireActual('react-native-safe-area-context'),
  useSafeAreaInsets: () => ({ top: 44, bottom: 34, left: 0, right: 0 }),
}));
jest.mock('@smileid/usesmileid', () => ({
  ...jest.requireActual('@smileid/usesmileid'),
  UseSmileIDBuilder: () => null,
}));

/// Waits out a step's slide, so the next tap lands on the page that moved in.
const settle = () => act(async () => await new Promise((resolve) => setTimeout(resolve, NjiaDefaults.motionDurationMs + 50)));

beforeEach(() => {
  smileIDSampleResetLaunchArgs();
  useSmileIDSampleSessionStore.getState().reset();
  useSmileIDSampleResultStore.getState().reset();
  // A run that failed before it was submitted: the fallback's action is Close.
  useSmileIDSampleResultStore.getState().record('failed', { errorResolution: smileIDSampleErrorSubmissionFallback });
});

describe("a failed run's banner on its details page", () => {
  it('closes to products again on a later visit, as its page stays on the verifications tab', async () => {
    const { model } = smileIDSampleReferenceNavigation();
    smileIDSampleStartShell('usesmileid-sample-expo://verifications/unsubmitted', smileIDSampleLaunchArgDefaults);
    const screen = await render(
      <UseSmileIDSampleThemeProvider dark={false}>
        <UseSmileIDSampleShell args={smileIDSampleLaunchArgDefaults} />
      </UseSmileIDSampleThemeProvider>,
    );
    await settle();
    const engine = () => model.engine!;

    fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.ERROR_ACTION));
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('products'));

    fireEvent.press(screen.getByTestId('sample_nav_verifications'));
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('verificationDetails'));
    await settle();

    fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.ERROR_ACTION));
    await waitFor(() => expect(smileIDSampleTopKind(engine())).toBe('products'));
    screen.unmount();
  });
});
