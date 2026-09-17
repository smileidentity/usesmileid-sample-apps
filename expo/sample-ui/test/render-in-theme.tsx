import { fireEvent, render } from '@testing-library/react-native';
import type { ReactElement } from 'react';
import { PixelRatio } from 'react-native';
import { SafeAreaProvider, type Metrics } from 'react-native-safe-area-context';

import { UseSmileIDSampleThemeProvider } from '../src/theme/use-smile-id-sample-theme';

/// The two schemes every golden is recorded in, named so a suite reads as light-then-dark.
export const schemes = [
  { name: 'light', dark: false },
  { name: 'dark', dark: true },
] as const;

/// The design's own scale. jest-expo reports 2 by default, which silently recorded every baseline at
/// enlarged type and left the layout the design draws with no coverage at all.
export const DESIGN_FONT_SCALE = 1;

/// What the no-clipping predicate is written against; a scale-sensitive state records here as well.
export const ENLARGED_FONT_SCALE = 2;

/// Pinned insets and a 393-wide frame: all four platforms render 393 logical units wide, so a crop
/// expressed in those units lands on the same content on each and a comparison becomes a measurement.
const metrics: Metrics = {
  frame: { x: 0, y: 0, width: 393, height: 852 },
  insets: { top: 44, left: 0, right: 0, bottom: 34 },
};

type Rendered = Awaited<ReturnType<typeof render>>;

/// Drives a component into a state it only reaches by interaction — focus, or a press held down.
export type Interaction = (rendered: Rendered) => Promise<void> | void;

/// Renders one component at a pinned scheme and font scale, so a golden depends on neither the
/// runner's appearance nor the preset's idea of a font scale.
export const renderInTheme = (element: ReactElement, dark: boolean, fontScale = DESIGN_FONT_SCALE) => {
  jest.spyOn(PixelRatio, 'getFontScale').mockReturnValue(fontScale);
  return render(
    <SafeAreaProvider initialMetrics={metrics}>
      <UseSmileIDSampleThemeProvider dark={dark}>{element}</UseSmileIDSampleThemeProvider>
    </SafeAreaProvider>,
  );
};

/// The rendered tree with its resolved styles, which is what a token or metric regression changes.
export const styleTree = async (
  element: ReactElement,
  dark: boolean,
  interact?: Interaction,
  fontScale = DESIGN_FONT_SCALE,
) => {
  const rendered = await renderInTheme(element, dark, fontScale);
  if (interact) await interact(rendered);
  return withoutHarness(rendered.toJSON());
};

type Json = ReturnType<Rendered['toJSON']>;

/// Records the component rather than the harness: the inset provider is a host element, and leaving
/// it in put twelve lines of framing at the top of every baseline.
const withoutHarness = (tree: Json): Json => {
  if (tree === null || Array.isArray(tree) || tree.type !== 'RNCSafeAreaProvider') return tree;
  const only = (tree.children ?? [])[0];
  // Anything but a single child keeps the wrapper, so unwrapping can never drop content.
  if ((tree.children ?? []).length !== 1 || only === null || typeof only !== 'object') return tree;
  return only as Json;
};

/// Focus, which is what turns a field's border from `input.border` to `input.border-focus`.
export const focusField = (testID: string): Interaction => (rendered) => {
  fireEvent(rendered.getByTestId(testID), 'focus');
};

/// A press held down, which a style function only reports while the finger is on the control.
export const pressIn = (testID: string): Interaction => (rendered) => {
  fireEvent(rendered.getByTestId(testID), 'pressIn');
};
