import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

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
  readonly label: (strings: UseSmileIDSampleStrings) => string;
}[] = [
  { id: UseSmileIDSampleCaptureMode.Auto, label: (strings) => strings.captureModeAuto },
  { id: UseSmileIDSampleCaptureMode.Manual, label: (strings) => strings.captureModeManual },
  {
    id: UseSmileIDSampleCaptureMode.AutoWithFallback,
    label: (strings) => strings.captureModeAutoWithFallback,
  },
];

/// What the Settings line says for `mode`.
export const smileIDSampleCaptureModeLabel = (mode: UseSmileIDSampleCaptureMode, strings: UseSmileIDSampleStrings): string =>
  smileIDSampleCaptureModes.find((it) => it.id === mode)?.label(strings) ?? mode;
