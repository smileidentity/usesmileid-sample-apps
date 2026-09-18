import type { ReactElement } from 'react';

import { renderInTheme, withoutHarness } from '../render-in-theme';
import { loadLayoutEngine, type RenderedNode } from './layout-tree';

export { loadLayoutEngine };

/// Renders one component and hands back the host tree, with the inset provider unwrapped as the goldens do.
export const renderForLayout = async (
  element: ReactElement,
  {
    dark = false,
    fontScale = 1,
    insets,
  }: { dark?: boolean; fontScale?: number; insets?: { bottom?: number } } = {},
): Promise<RenderedNode> => {
  const rendered = await renderInTheme(element, dark, fontScale, insets);
  const tree = withoutHarness(rendered.toJSON());
  if (tree === null || Array.isArray(tree) || typeof tree === 'string') {
    throw new Error('a component laid out for measurement must render exactly one host element');
  }
  return tree as RenderedNode;
};
