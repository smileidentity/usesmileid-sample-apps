import { render } from '@testing-library/react-native';
import type { ReactElement } from 'react';

import { UseSmileIDSampleThemeProvider } from '../src/theme/use-smile-id-sample-theme';

/// The two schemes every golden is recorded in, named so a suite reads as light-then-dark.
export const schemes = [
  { name: 'light', dark: false },
  { name: 'dark', dark: true },
] as const;

/// Renders one component in a pinned scheme, so a golden never depends on the runner's appearance.
export const renderInTheme = (element: ReactElement, dark: boolean) =>
  render(<UseSmileIDSampleThemeProvider dark={dark}>{element}</UseSmileIDSampleThemeProvider>);

/// The rendered tree with its resolved styles, which is what a token or metric regression changes.
export const styleTree = async (element: ReactElement, dark: boolean) => {
  const rendered = await renderInTheme(element, dark);
  return rendered.toJSON();
};
