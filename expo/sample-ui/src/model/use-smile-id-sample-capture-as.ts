/// How the SDK photographs the chosen document; never what the server receives.
export const UseSmileIDSampleCaptureAs = {
  Automatic: 'automatic',
  GreenBook: 'greenBook',
  Passport: 'passport',
  Custom: 'custom',
} as const;

export type UseSmileIDSampleCaptureAs = (typeof UseSmileIDSampleCaptureAs)[keyof typeof UseSmileIDSampleCaptureAs];

/// The rows the capture-as sheet offers, in its order, with what each says.
export const smileIDSampleCaptureAsOptions: readonly {
  readonly id: UseSmileIDSampleCaptureAs;
  readonly label: string;
}[] = [
  { id: UseSmileIDSampleCaptureAs.Automatic, label: 'Automatic' },
  { id: UseSmileIDSampleCaptureAs.GreenBook, label: 'Green Book preset' },
  { id: UseSmileIDSampleCaptureAs.Passport, label: 'Passport preset' },
  { id: UseSmileIDSampleCaptureAs.Custom, label: 'Custom' },
];
