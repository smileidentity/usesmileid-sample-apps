import { act } from '@testing-library/react-native';

import { ScanTokenScreen, type UseSmileIDSampleViewfinderProps } from '../src/screens/scan-token-screen';
import { renderInTheme } from './render-in-theme';

const base64Url = (text: string) => Buffer.from(text, 'utf8').toString('base64url');
const now = Math.floor(Date.now() / 1000);
const token = ['{"alg":"none"}', `{"iat":${now},"exp":${now + 900},"api_url":"https://testapi.smileidentity.com/v3"}`, 's']
  .map(base64Url)
  .join('.');

/// The scanned code, delivered as the camera delivers one.
let deliver: ((candidate: string) => void) | null = null;
const Viewfinder = ({ onCandidate }: UseSmileIDSampleViewfinderProps) => {
  deliver = onCandidate;
  return null;
};

describe('a scanned code', () => {
  it.each([
    ['a token', token, ['linked']],
    ['something that is not one', 'not-a-jwt', ['rejected']],
  ])('plays one acknowledgement for %s', async (_name, candidate, expected) => {
    const feedback: string[] = [];
    await renderInTheme(
      <ScanTokenScreen
        onBack={() => undefined}
        onLink={() => undefined}
        onSimulate={() => undefined}
        Viewfinder={Viewfinder}
        onFeedback={(kind) => feedback.push(kind)}
      />,
      false,
    );
    await act(async () => {
      deliver!(candidate);
    });
    expect(feedback).toEqual(expected);
  });
});
