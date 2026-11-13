import { View } from 'react-native';

import { UseSmileIDSampleBottomSheet } from '../src/components/use-smile-id-sample-bottom-sheet';
import { layoutTree } from './layout/layout-tree';
import { loadLayoutEngine, renderForLayout } from './layout/render-for-layout';
import { NARROW_WIDTH, WIDE_WIDTH } from './layout/text-scale';
import { PINNED_BOTTOM_INSET } from './render-in-theme';

const noop = () => {};

const sheet = (fullHeight: boolean) => (
  <UseSmileIDSampleBottomSheet onDismiss={noop} title="Theme" fullHeight={fullHeight}>
    <View style={{ height: 48 }} />
  </UseSmileIDSampleBottomSheet>
);

const height = async (fullHeight: boolean, width: number, bottom?: number) => {
  const tree = await renderForLayout(sheet(fullHeight), bottom === undefined ? {} : { insets: { bottom } });
  return layoutTree(tree, { width }).height;
};

beforeAll(loadLayoutEngine);

describe('a sheet clears the system navigation area', () => {
  // njia pins the sheet's panel to the screen's bottom edge, so the last row sits under a three-button bar unless the sheet reserves the inset.
  it.each([false, true])('carries the bottom inset exactly once (full height: %s)', async (fullHeight) => {
    for (const width of [NARROW_WIDTH, WIDE_WIDTH]) {
      const withInset = await height(fullHeight, width);
      const without = await height(fullHeight, width, 0);
      expect({ width, difference: withInset - without }).toEqual({ width, difference: PINNED_BOTTOM_INSET });
    }
  });
});
