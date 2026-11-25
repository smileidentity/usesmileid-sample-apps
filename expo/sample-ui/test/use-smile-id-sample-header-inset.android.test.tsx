import type { ReactElement } from 'react';
import { StyleSheet, Text, type StyleProp, type ViewStyle } from 'react-native';

import {
  UseSmileIDSampleTopCutoutContext,
  useSmileIDSampleHeaderTopInset,
} from '../src/components/use-smile-id-sample-header-inset';
import { UseSmileIDSampleTopAppBar } from '../src/components/use-smile-id-sample-top-app-bar';
import { smileDimens } from '../src/theme/smile-dimens';
import { renderInTheme } from './render-in-theme';

const noop = () => {};

/// A punch-hole phone's 37dp status bar.
const STATUS_BAR = 37;

/// [element] on a phone whose screen has a camera cutout along its top edge.
const underTopCutout = (element: ReactElement) => (
  <UseSmileIDSampleTopCutoutContext.Provider value>{element}</UseSmileIDSampleTopCutoutContext.Provider>
);

/// The flattened style of the node carrying [testID].
const styleOf = (rendered: Awaited<ReturnType<typeof renderInTheme>>, testID: string): ViewStyle =>
  StyleSheet.flatten(rendered.getByTestId(testID).props.style as StyleProp<ViewStyle>) ?? {};

const HeaderInsetProbe = () => <Text testID="probe">{useSmileIDSampleHeaderTopInset()}</Text>;

const probed = async (element: ReactElement, top: number) =>
  (await renderInTheme(element, false, undefined, { top })).getByTestId('probe').props.children as number;

/// On an Android phone with a top camera cutout, the status bar ends flush with it, so a header keeps a small gap below.
describe('the header inset under Android', () => {
  it('puts the back button a small gap below the status bar under a top cutout', async () => {
    const rendered = await renderInTheme(
      underTopCutout(<UseSmileIDSampleTopAppBar title="Open-source licenses" onBack={noop} testID="bar" />),
      false,
      undefined,
      { top: STATUS_BAR },
    );
    expect(styleOf(rendered, 'bar').paddingTop).toBe(STATUS_BAR + smileDimens.spacing.sm);
  });

  it('gives a tab header the same gap under a top cutout', async () => {
    expect(await probed(underTopCutout(<HeaderInsetProbe />), STATUS_BAR)).toBe(STATUS_BAR + smileDimens.spacing.sm);
  });

  it('adds nothing on a phone without a top cutout', async () => {
    expect(await probed(<HeaderInsetProbe />, 24)).toBe(24);
  });

  it('adds nothing without a status bar, as inside the large-screen frame', async () => {
    expect(await probed(underTopCutout(<HeaderInsetProbe />), 0)).toBe(0);
  });
});
