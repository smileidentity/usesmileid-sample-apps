import { createElement as mockCreateElement, type ReactNode } from 'react';

import {
  UseSmileIDSampleHapticsContext,
  type UseSmileIDSampleHaptics,
} from '../src/components/use-smile-id-sample-press-feedback';
import { UseSmileIDSampleSwitch } from '../src/components/use-smile-id-sample-switch';
import { renderInTheme } from './render-in-theme';

jest.mock('@expo/ui/jetpack-compose', () => ({
  Host: ({ children }: { children: ReactNode }) => mockCreateElement('ComposeHost', null, children),
  Switch: (props: Record<string, unknown>) => mockCreateElement('ComposeSwitch', props),
}));
jest.mock('@expo/ui/jetpack-compose/modifiers', () => ({
  testID: (id: string) => ({ $type: 'testID', testID: id }),
}));

type HostNode = { type: string; props: Record<string, unknown>; children: (HostNode | string)[] | null };

const composeSwitch = (node: HostNode | HostNode[] | string | null): HostNode | undefined => {
  if (node === null || typeof node === 'string') return undefined;
  if (Array.isArray(node)) return node.map(composeSwitch).find(Boolean);
  if (node.type === 'ComposeSwitch') return node;
  return (node.children ?? []).map(composeSwitch).find(Boolean);
};

const toggleTo = async (checked: boolean) => {
  const played: string[] = [];
  const haptics: UseSmileIDSampleHaptics = {
    selection: () => played.push('selection'),
    toggle: (on) => played.push(on ? 'toggle-on' : 'toggle-off'),
  };
  const rendered = await renderInTheme(
    <UseSmileIDSampleHapticsContext.Provider value={haptics}>
      <UseSmileIDSampleSwitch checked={!checked} onCheckedChange={() => {}} />
    </UseSmileIDSampleHapticsContext.Provider>,
    false,
  );
  const change = composeSwitch(rendered.toJSON() as HostNode | null)?.props.onCheckedChange as
    | ((value: boolean) => void)
    | undefined;
  change?.(checked);
  return played;
};

describe("Android's switch", () => {
  it('ticks on when turned on', async () => {
    expect(await toggleTo(true)).toEqual(['toggle-on']);
  });

  it('ticks off when turned off', async () => {
    expect(await toggleTo(false)).toEqual(['toggle-off']);
  });
});
