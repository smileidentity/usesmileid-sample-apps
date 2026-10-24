import { useLayoutEffect } from 'react';

/// Draws nothing and calls `onLeave` once it has mounted: a step that can't show leaves rather than render.
export const UseSmileIDSampleLeave = ({ onLeave }: { onLeave: () => void }) => {
  useLayoutEffect(() => {
    onLeave();
    // Once, at mount: the step has already decided it can't show.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return null;
};
