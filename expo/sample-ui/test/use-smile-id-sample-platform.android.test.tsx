import { createElement as mockCreateElement, type ReactNode } from 'react';
import { Platform, StyleSheet, Text, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleBottomSheet } from '../src/components/use-smile-id-sample-bottom-sheet';
import {
  SMILE_TOKEN_FLOAT_ELEVATION,
  UseSmileIDSampleFloatingTokenButton,
} from '../src/components/use-smile-id-sample-floating-token-button';
import { SMILE_NAV_BAR_ELEVATION, UseSmileIDSampleNavBar } from '../src/components/use-smile-id-sample-nav-bar';
import { UseSmileIDSampleSwitch } from '../src/components/use-smile-id-sample-switch';
import { smileDimens } from '../src/theme/smile-dimens';
import { renderInTheme } from './render-in-theme';

/// The Compose views are native; stand-ins keep their props where a query can read them.
jest.mock('@expo/ui/jetpack-compose', () => ({
  Host: ({ children }: { children: ReactNode }) => mockCreateElement('ComposeHost', null, children),
  Switch: (props: Record<string, unknown>) => mockCreateElement('ComposeSwitch', props),
}));
jest.mock('@expo/ui/jetpack-compose/modifiers', () => ({
  testID: (id: string) => ({ $type: 'testID', testID: id }),
}));
jest.mock('@expo/ui/community/bottom-sheet', () => ({
  BottomSheet: ({ children, ...props }: { children: ReactNode }) => mockCreateElement('ComposeSheet', props, children),
}));

const noop = () => {};

type HostNode = { type: string; props: Record<string, unknown>; children: (HostNode | string)[] | null };

/// Every host element in a render, parents first.
const hostNodes = (tree: unknown): HostNode[] => {
  if (tree === null || typeof tree !== 'object') return [];
  if (Array.isArray(tree)) return tree.flatMap(hostNodes);
  const node = tree as HostNode;
  return [node, ...(node.children ?? []).flatMap(hostNodes)];
};

/// The flattened styles of every View in a render.
const viewStyles = (tree: unknown) =>
  hostNodes(tree)
    .filter((node) => node.type === 'View')
    .map((node): ViewStyle => StyleSheet.flatten(node.props.style as StyleProp<ViewStyle>) ?? {});

describe('under Android resolution', () => {
  it('is running as Android, or nothing below proves anything', () => {
    expect(Platform.OS).toBe('android');
  });

  it("mounts Compose's switch with its test id, and forwards a change", async () => {
    const changes: boolean[] = [];
    const rendered = await renderInTheme(
      <UseSmileIDSampleSwitch checked={false} onCheckedChange={(value) => changes.push(value)} testID="probe" />,
      false,
    );
    const [toggle] = hostNodes(rendered.toJSON()).filter((node) => node.type === 'ComposeSwitch');
    expect(toggle?.props.modifiers).toEqual([{ $type: 'testID', testID: 'probe' }]);
    expect(toggle?.props.value).toBe(false);
    (toggle?.props.onCheckedChange as (value: boolean) => void)(true);
    expect(changes).toEqual([true]);
  });

  it("lays touch targets out at Material's 48", () => {
    expect(smileDimens.touchTarget).toBe(48);
  });

  it("draws the Compose app's 44x4 handle in place of Material's own", async () => {
    const rendered = await renderInTheme(
      <UseSmileIDSampleBottomSheet visible title="Switch profile" onDismiss={noop}>
        <Text>row</Text>
      </UseSmileIDSampleBottomSheet>,
      false,
    );
    const [sheet] = hostNodes(rendered.toJSON()).filter((node) => node.type === 'ComposeSheet');
    expect(sheet?.props.handleComponent).toBeNull();
    const pills = viewStyles(rendered.toJSON()).filter((style) => style.width === 44 && style.height === 4);
    expect(pills).toHaveLength(1);
  });

  it("gives the bar and the token Compose's elevation rather than the iOS shadow", async () => {
    const rendered = await renderInTheme(
      <UseSmileIDSampleNavBar selectedId="products" onSelect={noop} onTokenPress={noop} />,
      false,
    );
    const elevations = viewStyles(rendered.toJSON())
      .map((style) => style.elevation)
      .filter((elevation) => elevation !== undefined);
    expect(elevations).toEqual([SMILE_NAV_BAR_ELEVATION, SMILE_NAV_BAR_ELEVATION]);
  });

  it("gives the floating token button Compose's 4dp elevation rather than the iOS shadow", async () => {
    const rendered = await renderInTheme(<UseSmileIDSampleFloatingTokenButton onPress={noop} />, false);
    const [button] = viewStyles(rendered.toJSON());
    expect(button?.elevation).toBe(SMILE_TOKEN_FLOAT_ELEVATION);
    expect(button?.shadowOpacity).toBeUndefined();
  });
});
