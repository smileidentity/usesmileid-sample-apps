import { render } from '@testing-library/react-native';

import { UseSmileIDSampleDebugSheetStep } from '../src/steps/use-smile-id-sample-settings-sheets';

jest.mock('../src/extension', () => ({
  useSmileIDSampleShellExtension: {
    hasDebugSheet: (sheetId: string) => sheetId === 'captureTimings',
    debugSheet: (sheetId: string) => {
      const { Text: MockText } = jest.requireActual('react-native');
      return <MockText>{`sheet ${sheetId}`}</MockText>;
    },
  },
}));

/// A step scope whose `back` counts, renewed per render as a host may renew its navigator.
const scope = (sheetId: string, back: jest.Mock) => ({ entry: { arg: sheetId }, navigator: { back } }) as never;

/// The step closes exactly once for a sheet it can't draw, and never for one it can.
describe('the debug sheet step', () => {
  it('draws a sheet its extension draws and stays open', async () => {
    const back = jest.fn();
    const rendered = await render(<UseSmileIDSampleDebugSheetStep scope={scope('captureTimings', back)} />);
    expect(rendered.getByText('sheet captureTimings')).toBeTruthy();
    expect(back).not.toHaveBeenCalled();
  });

  it('closes once for an id the extension does not draw, even after a re-render', async () => {
    const back = jest.fn();
    const rendered = await render(<UseSmileIDSampleDebugSheetStep scope={scope('unknown', back)} />);
    await rendered.rerender(<UseSmileIDSampleDebugSheetStep scope={scope('unknown', back)} />);
    expect(back).toHaveBeenCalledTimes(1);
    expect(rendered.queryByText(/sheet/)).toBeNull();
  });
});
