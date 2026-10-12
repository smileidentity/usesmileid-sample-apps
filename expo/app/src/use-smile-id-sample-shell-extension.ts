import type { ReactNode } from 'react';
import type { UseSmileIDSampleProduct, UseSmileIDSampleTokenSession } from '@smileid/sample-ui';
import type { UseSmileIDFlowBuilder } from '@smileid/usesmileid';

/// Developer tooling an SDK repo's source build adds to this app; a registry build has none.
export type UseSmileIDSampleShellExtension = {
  /// Extra rows for the Settings DEBUG section.
  debugRows?: (host: UseSmileIDSampleShellHost) => ReactNode;
  /// Runs after the shell has configured a flow, so it may replace any of that configuration.
  customiseFlow?: (builder: UseSmileIDFlowBuilder, product: UseSmileIDSampleProduct) => void;
  /// Runs once at launch, with the link the app was opened by.
  onLaunch?: (initialUrl: string | null) => void;
};

/// What the shell lets an extension do; this shell has no scenario drawer to open.
type UseSmileIDSampleShellHost = {
  linkTokenSession: (session: UseSmileIDSampleTokenSession) => Promise<void>;
};
