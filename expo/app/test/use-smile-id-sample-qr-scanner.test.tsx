import { render } from '@testing-library/react-native';

import { UseSmileIDSampleQrScanner } from '../src/scan/use-smile-id-sample-qr-scanner';

/// The permission the next render reports.
let mockPermission: { granted: boolean; canAskAgain: boolean; status: string } | null = null;
const mockRequest = jest.fn(async () => mockPermission);
/// Every camera the scanner mounted.
const mockCamera = jest.fn((_props: object) => null);
jest.mock('expo-camera', () => ({
  CameraView: (props: object) => mockCamera(props),
  useCameraPermissions: () => [mockPermission, mockRequest],
}));

beforeEach(() => {
  mockRequest.mockClear();
  mockCamera.mockClear();
});

describe('the scanner camera permission', () => {
  it('asks once per visit, so a denial is not answered with the same dialog again', async () => {
    mockPermission = { granted: false, canAskAgain: true, status: 'undetermined' };
    const screen = await render(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} focused />);
    mockPermission = { granted: false, canAskAgain: true, status: 'denied' };
    await screen.rerender(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} focused />);
    mockPermission = { granted: false, canAskAgain: true, status: 'denied' };
    await screen.rerender(<UseSmileIDSampleQrScanner enabled={false} onCandidate={() => undefined} torchOn={false} focused />);
    expect(mockRequest).toHaveBeenCalledTimes(1);
  });

  it('does not ask while the permission is still loading, or once it can no longer ask', async () => {
    mockPermission = null;
    const screen = await render(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} focused />);
    mockPermission = { granted: false, canAskAgain: false, status: 'denied' };
    await screen.rerender(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} focused />);
    expect(mockRequest).not.toHaveBeenCalled();
  });
});

describe('the scanner camera', () => {
  it('is released once another step covers the scanner, so the SDK never inherits it', async () => {
    mockPermission = { granted: true, canAskAgain: true, status: 'granted' };
    const screen = await render(<UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} focused />);
    expect(mockCamera).toHaveBeenCalled();
    mockCamera.mockClear();
    await screen.rerender(
      <UseSmileIDSampleQrScanner enabled onCandidate={() => undefined} torchOn={false} focused={false} />,
    );
    expect(mockCamera).not.toHaveBeenCalled();
  });
});
