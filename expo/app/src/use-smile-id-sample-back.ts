import { useRouter, type Href } from 'expo-router';
import { useCallback } from 'react';

/// Back, or to the screen that owns this one when there is no history to go back to.
export const useSmileIDSampleBack = (fallback: Href): (() => void) => {
  const router = useRouter();
  return useCallback(() => {
    // Every screen here is deep-linkable, so any of them can be first in the stack, where `back`
    // does nothing at all and strands the reader on a screen with no way out.
    if (router.canGoBack()) {
      router.back();
      return;
    }
    router.replace(fallback);
  }, [router, fallback]);
};
