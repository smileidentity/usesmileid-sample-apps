/// Where the scanner is.
export type UseSmileIDSampleScanState =
  | { readonly kind: 'searching' }
  | { readonly kind: 'found' }
  /// The handle and the time left, never the token.
  | { readonly kind: 'linked'; readonly handle: string; readonly remaining: string }
  | { readonly kind: 'rejected'; readonly reason: string };

/// Why the scanner opened, worded once for every host.
export const UseSmileIDSampleScanReason = {
  sessionEnded: 'Token session ended. Scan to continue where you left off.',
} as const;

export type UseSmileIDSampleScanReason = keyof typeof UseSmileIDSampleScanReason;
