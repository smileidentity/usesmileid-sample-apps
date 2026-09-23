/// Where the scanner is: looking, holding a code it is decoding, linked, or refusing what it read.
export type UseSmileIDSampleScanState =
  | { readonly kind: 'searching' }
  | { readonly kind: 'found' }
  /// The handle and the time left: never the token, which no surface here may show.
  | { readonly kind: 'linked'; readonly handle: string; readonly remaining: string }
  | { readonly kind: 'rejected'; readonly reason: string };

/// Why the scanner opened. The copy lives here so the golden pins the sentence the app ships.
export const UseSmileIDSampleScanReason = {
  sessionEnded: 'Token session ended. Scan to continue where you left off.',
} as const;

export type UseSmileIDSampleScanReason = keyof typeof UseSmileIDSampleScanReason;
