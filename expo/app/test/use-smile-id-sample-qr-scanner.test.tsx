import { render } from '@testing-library/react-native';

import { UseSmileIDSampleQrScanner } from '../src/scan/use-smile-id-sample-qr-scanner';

/// The permission the next render reports.
let mockPermission: { granted: boolean; canAskAgain: boolean; status: string } | null = null;
const mockRequest = jest.fn(async () => mockPermission);
jest.mock('expo-camera', () => ({
  CameraView: () => null,
  useCameraPermissions: () => [mockPermission, mockRequest],
}));
jest.mock('expo-router', () => ({ useIsFocused: () => true }));

beforeEach(() => {
  mockRequest.mockClear();
});

describe('the scanner camera permission', () => {
  it('asks once per visit, so a denial is not answered with the same dialog again', async () => {
    mockPermission = { granted: false, canAskAgain: true, status: 'undetermined' };
    const screen = await render(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} />);
    mockPermission = { granted: false, canAskAgain: true, status: 'denied' };
    await screen.rerender(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} />);
    mockPermission = { granted: false, canAskAgain: true, status: 'denied' };
    await screen.rerender(<UseSmileIDSampleQrScanner enabled={false} onCandidate={() => undefined} torchOn={false} />);
    expect(mockRequest).toHaveBeenCalledTimes(1);
  });

  it('does not ask while the permission is still loading, or once it can no longer ask', async () => {
    mockPermission = null;
    const screen = await render(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} />);
    mockPermission = { granted: false, canAskAgain: false, status: 'denied' };
    await screen.rerender(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} />);
    expect(mockRequest).not.toHaveBeenCalled();
  });
});
