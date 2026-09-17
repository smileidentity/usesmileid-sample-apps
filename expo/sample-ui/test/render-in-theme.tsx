import { fireEvent, render } from '@testing-library/react-native';
import type { ReactElement } from 'react';

import { UseSmileIDSampleThemeProvider } from '../src/theme/use-smile-id-sample-theme';

/// The two schemes every golden is recorded in, named so a suite reads as light-then-dark.
export const schemes = [
  { name: 'light', dark: false },
  { name: 'dark', dark: true },
] as const;

type Rendered = Awaited<ReturnType<typeof render>>;

/// Drives a component into a state it only reaches by interaction — focus, or a press held down.
export type Interaction = (rendered: Rendered) => Promise<void> | void;

/// Renders one component in a pinned scheme, so a golden never depends on the runner's appearance.
export const renderInTheme = (element: ReactElement, dark: boolean) =>
  render(<UseSmileIDSampleThemeProvider dark={dark}>{element}</UseSmileIDSampleThemeProvider>);

/// The rendered tree with its resolved styles, which is what a token or metric regression changes.
export const styleTree = async (element: ReactElement, dark: boolean, interact?: Interaction) => {
  const rendered = await renderInTheme(element, dark);
  if (interact) await interact(rendered);
  return rendered.toJSON();
};

/// Focus, which is what turns a field's border from `input.border` to `input.border-focus`.
export const focusField = (testID: string): Interaction => (rendered) => {
  fireEvent(rendered.getByTestId(testID), 'focus');
};

/// A press held down, which a style function only reports while the finger is on the control.
export const pressIn = (testID: string): Interaction => (rendered) => {
  fireEvent(rendered.getByTestId(testID), 'pressIn');
};
