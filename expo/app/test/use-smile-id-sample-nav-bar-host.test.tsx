import { UseSmileIDSampleTestIds, UseSmileIDSampleThemeProvider, smileDimens } from '@smileid/sample-ui';
import { fireEvent, render, screen, waitFor } from '@testing-library/react-native';
import {
  BottomTabBarHeightCallbackContext,
  BottomTabBarHeightContext,
  type BottomTabBarProps,
} from 'expo-router/tabs';
import { useEffect } from 'react';
import { Text } from 'react-native';
import { SafeAreaProvider, type Metrics } from 'react-native-safe-area-context';

import { useSmileIDSampleListInset } from '../src/use-smile-id-sample-list-inset';
import { UseSmileIDSampleNavBarHost } from '../src/use-smile-id-sample-nav-bar-host';
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

/// What React Navigation seeds the height with before anything publishes: the stock bar's 49 plus the inset.
const STOCK_DEFAULT = 49 + 34;

const navigation = { emit: () => ({ defaultPrevented: false }), navigate: () => {} };

const barProps = (focused: string): BottomTabBarProps =>
  ({
    state: {
      index: 0,
      key: 'tabs',
      routes: [{ key: `${focused}-1`, name: focused }],
    },
    navigation,
    descriptors: {},
    insets: metrics.insets,
  }) as unknown as BottomTabBarProps;

const renderBar = (focused: string, onHeightChange: (height: number) => void) =>
  render(
    <SafeAreaProvider initialMetrics={metrics}>
      <UseSmileIDSampleThemeProvider dark={false}>
        <BottomTabBarHeightCallbackContext.Provider value={onHeightChange}>
          <UseSmileIDSampleNavBarHost {...barProps(focused)} />
        </BottomTabBarHeightCallbackContext.Provider>
      </UseSmileIDSampleThemeProvider>
    </SafeAreaProvider>,
  );

/// Reads the reserve exactly as a tab screen does, so the number under test is the shipped one.
const Reserve = () => <Text testID="reserve">{String(useSmileIDSampleListInset())}</Text>;

const renderReserve = (published: number) =>
  render(
    <SafeAreaProvider initialMetrics={metrics}>
      <UseSmileIDSampleThemeProvider dark={false}>
        <BottomTabBarHeightContext.Provider value={published}>
          <Reserve />
        </BottomTabBarHeightContext.Provider>
      </UseSmileIDSampleThemeProvider>
    </SafeAreaProvider>,
  );

describe('the bar publishes the height it was laid out at', () => {
  it('reports its own measured height, not the default React Navigation seeded', async () => {
    const published: number[] = [];
    await renderBar('products', (height) => published.push(height));
    fireEvent(screen.getByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS).parent!.parent!.parent!, 'layout', {
      nativeEvent: { layout: { height: MEASURED_BAR, width: 320, x: 0, y: 0 } },
    });
    expect(published).toEqual([MEASURED_BAR]);
    expect(published).not.toContain(STOCK_DEFAULT);
  });

  it('draws no bar on a route the design draws without one', async () => {
    await renderBar('settings/licenses', () => {});
    expect(screen.queryByTestId(UseSmileIDSampleTestIds.NAV_PRODUCTS)).toBeNull();
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
  /// Drives the context the verifications route drives, so the test enters select mode the same way.
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
            <BottomTabBarHeightCallbackContext.Provider value={() => undefined}>
              <UseSmileIDSampleNavBarHost {...barProps('verifications')} />
            </BottomTabBarHeightCallbackContext.Provider>
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
