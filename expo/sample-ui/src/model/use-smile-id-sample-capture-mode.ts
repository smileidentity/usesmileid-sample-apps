/// DocumentCaptureConfig.captureMode's three values; the fallback keeps the SDK's 10 seconds.
export const UseSmileIDSampleCaptureMode = {
  Auto: 'auto',
  Manual: 'manual',
  AutoWithFallback: 'autoWithFallback',
} as const;

export type UseSmileIDSampleCaptureMode =
  (typeof UseSmileIDSampleCaptureMode)[keyof typeof UseSmileIDSampleCaptureMode];

/// The sheet's rows in order, with what each and the Settings line say.
export const smileIDSampleCaptureModes: readonly {
  readonly id: UseSmileIDSampleCaptureMode;
  readonly label: string;
}[] = [
  { id: UseSmileIDSampleCaptureMode.Auto, label: 'Automatic' },
  { id: UseSmileIDSampleCaptureMode.Manual, label: 'Manual' },
  {
    id: UseSmileIDSampleCaptureMode.AutoWithFallback,
    label: 'Automatic with manual fallback',
  },
];

/// What the Settings line says for `mode`.
export const smileIDSampleCaptureModeLabel = (mode: UseSmileIDSampleCaptureMode): string =>
  smileIDSampleCaptureModes.find((it) => it.id === mode)?.label ?? mode;
