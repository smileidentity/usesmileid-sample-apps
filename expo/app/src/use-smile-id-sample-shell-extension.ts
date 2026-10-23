import { createElement, Fragment, type ReactNode } from 'react';
import type { UseSmileIDSampleProduct, UseSmileIDSampleTokenSession } from '@smileid/sample-ui';
import type { UseSmileIDFlowBuilder, UseSmileIDNetworkBuilder } from '@smileid/usesmileid';

/// Developer tooling an SDK repo's source build adds to this app; a registry build has none.
export type UseSmileIDSampleShellExtension = {
  /// Rows for the Settings DEBUG section above the shell's own, such as an identity the rows below refer to.
  leadingDebugRows?: () => ReactNode;
  /// Extra rows for the Settings DEBUG section, below the shell's own.
  debugRows?: () => ReactNode;
  /// Runs after the shell has configured a flow, so it may replace any of that configuration.
  customiseFlow?: (builder: UseSmileIDFlowBuilder, product: UseSmileIDSampleProduct) => void;
  /// Runs last inside the shell's network block, so it may add to that configuration without replacing it.
  customiseNetwork?: (network: UseSmileIDNetworkBuilder, product: UseSmileIDSampleProduct) => void;
  /// Runs once per JavaScript process, before any other member, with the cold-start link; a throw fails the launch.
  onLaunch?: (initialUrl: string | null) => void | Promise<void>;
  /// A session the shell links once, after `onLaunch` and before autostart, as if its token had been scanned.
  launchSession?: () => UseSmileIDSampleTokenSession | null | Promise<UseSmileIDSampleTokenSession | null>;
};

/// Links the extension's launch session through `link`, if it offers one; a failed link only skips it.
export const linkLaunchSession = async (
  extension: UseSmileIDSampleShellExtension | null | undefined,
  link: (session: UseSmileIDSampleTokenSession) => Promise<void>,
): Promise<void> => {
  try {
    const session = await (extension?.launchSession?.() ?? null);
    if (session) await link(session);
  } catch {
    // Nothing to recover: the app runs without it, as it would without the extension.
  }
};

/// The DEBUG section's rows below Scenarios: the extension's leading rows, then its others; none without an extension.
export const smileIDSampleDebugRows = (extension: UseSmileIDSampleShellExtension | null | undefined): ReactNode => {
  const rows = [extension?.leadingDebugRows?.(), extension?.debugRows?.()].filter(
    (row) => row !== undefined && row !== null && row !== false,
  );
  // Undefined rather than an empty fragment, which the settings screen would read as rows to show.
  return rows.length > 0 ? createElement(Fragment, null, ...rows) : undefined;
};
