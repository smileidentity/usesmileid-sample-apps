import {
  UseSmileIDSampleNavBar,
  smileIDSampleLiveSession,
  smileIDSampleSessionProgress,
  useSmileIDSampleSessionStore,
  useSmileIDSampleTheme,
} from '@smileid/sample-ui';
import { createContext, use, useState, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { useSmileIDSampleSelectMode } from './use-smile-id-sample-select-mode';

/// The floating bar's laid-out height, which a tab's list reserves beneath its last row; 0 where no bar is drawn.
export const UseSmileIDSampleBarHeightContext = createContext(0);

/// The bar's measured height, published by the page it floats over.
export const useSmileIDSampleBarHeight = (): number => use(UseSmileIDSampleBarHeightContext);

type Props = {
  /// The tab whose root this page is, or null for a screen pushed inside a tab, which draws no bar.
  readonly tab: string | null;
  readonly onSelect: (tab: string) => void;
  readonly onTokenPress: () => void;
  readonly children: ReactNode;
};

/// A tab's root with the pill floated over it, or a screen pushed inside a tab with none.
export const UseSmileIDSampleNavBarHost = ({ tab, onSelect, onTokenPress, children }: Props) => {
  const theme = useSmileIDSampleTheme();
  const [height, setHeight] = useState(0);
  // Select mode owns the bottom chrome; a bar left here covers Hide from List and eats its tap.
  const selecting = useSmileIDSampleSelectMode();
  const sessionProgress = useSmileIDSampleSessionStore((state) => {
    const live = smileIDSampleLiveSession(state, state.nowMillis);
    return live === null ? null : smileIDSampleSessionProgress(live, state.nowMillis);
  });
  const showsBar = tab !== null && !selecting;

  return (
    <View style={[styles.page, { backgroundColor: theme.colors.background }]}>
      <UseSmileIDSampleBarHeightContext value={showsBar ? height : 0}>{children}</UseSmileIDSampleBarHeightContext>
      {showsBar ? (
        <View
          // Absolute, or the bar is a column sibling that shortens the screens instead of floating over them.
          style={styles.bar}
          // box-none so the strip never eats a touch meant for whatever a screen anchors beneath it.
          pointerEvents="box-none"
          onLayout={(event) => setHeight(event.nativeEvent.layout.height)}
        >
          <UseSmileIDSampleNavBar
            selectedId={tab}
            // Re-selecting the showing tab pops it to its root, as the platform does.
            onSelect={(item) => onSelect(item.id)}
            onTokenPress={onTokenPress}
            sessionProgress={sessionProgress}
          />
        </View>
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  page: { flex: 1 },
  bar: { bottom: 0, left: 0, position: 'absolute', right: 0 },
});
