import { UseSmileIDSampleTestIds, UseSmileIDSampleThemeProvider, smileDimens } from '@smileid/sample-ui';
import { fireEvent, render, screen, waitFor } from '@testing-library/react-native';
import { useEffect } from 'react';
import { Text } from 'react-native';
import { SafeAreaProvider, type Metrics } from 'react-native-safe-area-context';

import { useSmileIDSampleListInset } from '../src/use-smile-id-sample-list-inset';
import { UseSmileIDSampleBarHeightContext, UseSmileIDSampleNavBarHost } from '../src/use-smile-id-sample-nav-bar-host';
import {
  UseSmileIDSampleSelectModeProvider,
  useSmileIDSampleSetSelectMode,
} from '../src/use-smile-id-sample-select-mode';

const metrics: Metrics = {
  frame: { x: 0, y: 0, width: 393, height: 852 },
  insets: { top: 44, left: 0, right: 0, bottom: 34 },
};

/// The height the library's own suite measures the pill at, narrowest frame and largest type.
const MEASURED_BAR = 191;

/// Reads the reserve exactly as a tab screen does, so the number under test is the shipped one.
const Reserve = () => <Text testID="reserve">{String(useSmileIDSampleListInset())}</Text>;

const renderBar = (tab: string | null, handlers: { onSelect?: (tab: string) => void; onTokenPress?: () => void } = {}) =>
  render(
    <SafeAreaProvider initialMetrics={metrics}>
      <UseSmileIDSampleThemeProvider dark={false}>
        <UseSmileIDSampleSelectModeProvider>
          <UseSmileIDSampleNavBarHost
            tab={tab}
            onSelect={handlers.onSelect ?? (() => undefined)}
            onTokenPress={handlers.onTokenPress ?? (() => undefined)}
          >
            <Reserve />
          </UseSmileIDSampleNavBarHost>
        </UseSmileIDSampleSelectModeProvider>
      </UseSmileIDSampleThemeProvider>
    </SafeAreaProvider>,
  );

const renderReserve = (published: number) =>
  render(
    <SafeAreaProvider initialMetrics={metrics}>
      <UseSmileIDSampleThemeProvider dark={false}>
        <UseSmileIDSampleBarHeightContext value={published}>
          <Reserve />
        </UseSmileIDSampleBarHeightContext>
      </UseSmileIDSampleThemeProvider>
    </SafeAreaProvider>,
  );

describe('the bar publishes the height it was laid out at to the page beneath it', () => {
  it('reserves its own measured height under the page, plus one gap', async () => {
    await renderBar('products');
    let strip = screen.getByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS);
    while (strip.props.onLayout === undefined) strip = strip.parent!;
    await fireEvent(strip, 'layout', {
      nativeEvent: { layout: { height: MEASURED_BAR, width: 320, x: 0, y: 0 } },
    });
    expect(screen.getByTestId('reserve')).toHaveTextContent(String(MEASURED_BAR + smileDimens.spacing.md));
  });

  it('draws no bar, and reserves nothing for one, on a screen pushed inside a tab', async () => {
    await renderBar(null);
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS)).toBeNull();
    expect(screen.getByTestId('reserve')).toHaveTextContent(String(smileDimens.spacing.md));
  });

  it('hands a tab tap and the token button to the shell', async () => {
    const selected: string[] = [];
    const onTokenPress = jest.fn();
    await renderBar('products', { onSelect: (tab) => selected.push(tab), onTokenPress });
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS));
    await fireEvent.press(screen.getByTestId(UseSmileIDSampleTestIds.NAV_TOKEN));
    expect(selected).toEqual(['products']);
    expect(onTokenPress).toHaveBeenCalledTimes(1);
  });
});

describe('a tab screen reserves what the bar published', () => {
  it('adds one gap to the published height and nothing else', async () => {
    await renderReserve(MEASURED_BAR);
    expect(screen.getByTestId('reserve')).toHaveTextContent(String(MEASURED_BAR + smileDimens.spacing.md));
  });

  it('follows the published height rather than a number of its own', async () => {
    await renderReserve(MEASURED_BAR + 60);
    expect(screen.getByTestId('reserve')).toHaveTextContent(
      String(MEASURED_BAR + 60 + smileDimens.spacing.md),
    );
  });

  it('clears a bar as tall as the library measures at its worst, by at least a gap', async () => {
    await renderReserve(MEASURED_BAR);
    const reserved = Number(screen.getByTestId('reserve').props.children);
    expect(reserved - MEASURED_BAR).toBeGreaterThanOrEqual(smileDimens.spacing.md);
  });
});

describe('the pill stands down while a screen owns the bottom chrome', () => {
  /// Drives the context the verifications step drives, so the test enters select mode the same way.
  const Enter = ({ selecting }: { selecting: boolean }) => {
    const set = useSmileIDSampleSetSelectMode();
    useEffect(() => set(selecting), [set, selecting]);
    return null;
  };

  const barIn = (selecting: boolean) =>
    render(
      <SafeAreaProvider initialMetrics={metrics}>
        <UseSmileIDSampleThemeProvider dark={false}>
          <UseSmileIDSampleSelectModeProvider>
            <Enter selecting={selecting} />
            <UseSmileIDSampleNavBarHost tab="verifications" onSelect={() => undefined} onTokenPress={() => undefined}>
              {null}
            </UseSmileIDSampleNavBarHost>
          </UseSmileIDSampleSelectModeProvider>
        </UseSmileIDSampleThemeProvider>
      </SafeAreaProvider>,
    );

  it('draws the pill when nothing else owns the bottom', async () => {
    await barIn(false);
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS)).not.toBeNull();
  });

  it('draws no pill in select mode, which is where it covered Hide from List', async () => {
    await barIn(true);
    await waitFor(() =>
      expect(screen.queryByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS)).toBeNull(),
    );
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.NAV_TOKEN)).toBeNull();
  });
});
