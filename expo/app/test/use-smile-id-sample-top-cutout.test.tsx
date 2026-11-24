import { act, render } from '@testing-library/react-native';
import { useContext } from 'react';
import { Text } from 'react-native';
import { UseSmileIDSampleTopCutoutContext } from '@smileid/sample-ui';

import {
  UseSmileIDSampleTopCutoutProvider,
  type UseSmileIDSampleCutoutModule,
} from '../src/use-smile-id-sample-top-cutout';

const Probe = () => <Text testID="probe">{String(useContext(UseSmileIDSampleTopCutoutContext))}</Text>;

/// A stand-in for the native module: a cached reading and the change event it pushes.
const fakeCutout = (initial: boolean) => {
  let reading = initial;
  const listeners = new Set<(event: { present: boolean }) => void>();
  const cutout: UseSmileIDSampleCutoutModule = {
    hasTopCutout: () => reading,
    addListener: (_event, listener) => {
      listeners.add(listener);
      return { remove: () => listeners.delete(listener) };
    },
  };
  const change = (present: boolean) => {
    reading = present;
    listeners.forEach((listener) => listener({ present }));
  };
  return { cutout, change, listening: () => listeners.size };
};

const shown = async (cutout: UseSmileIDSampleCutoutModule | null) =>
  render(
    <UseSmileIDSampleTopCutoutProvider cutout={cutout}>
      <Probe />
    </UseSmileIDSampleTopCutoutProvider>,
  );

/// The shared screens learn of a top camera cutout from the shell, which alone can read it natively.
describe('the top cutout the shell reports', () => {
  it('is what the native module has read', async () => {
    expect((await shown(fakeCutout(true).cutout)).getByTestId('probe').props.children).toBe('true');
    expect((await shown(fakeCutout(false).cutout)).getByTestId('probe').props.children).toBe('false');
  });

  it('follows the change the native module pushes, as on a rotation', async () => {
    const native = fakeCutout(true);
    const rendered = await shown(native.cutout);

    await act(async () => native.change(false));

    expect(rendered.getByTestId('probe').props.children).toBe('false');
  });

  it('stops listening when it unmounts', async () => {
    const native = fakeCutout(true);
    const rendered = await shown(native.cutout);
    expect(native.listening()).toBe(1);

    await act(async () => rendered.unmount());

    expect(native.listening()).toBe(0);
  });

  it('is none where there is no native module, as on iOS', async () => {
    expect((await shown(null)).getByTestId('probe').props.children).toBe('false');
  });
});
