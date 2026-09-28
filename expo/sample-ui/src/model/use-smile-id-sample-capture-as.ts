/// How the SDK photographs the chosen document, each the SDK's own type; never what the server receives.
export const UseSmileIDSampleCaptureAs = {
  GenericDocument: 'genericDocument',
  GreenBook: 'greenBook',
  Passport: 'passport',
} as const;

export type UseSmileIDSampleCaptureAs = (typeof UseSmileIDSampleCaptureAs)[keyof typeof UseSmileIDSampleCaptureAs];

/// The rows the capture-as sheet offers, in its order, with what each says.
export const smileIDSampleCaptureAsOptions: readonly {
  readonly id: UseSmileIDSampleCaptureAs;
  readonly label: string;
}[] = [
  { id: UseSmileIDSampleCaptureAs.GenericDocument, label: 'Generic document' },
  { id: UseSmileIDSampleCaptureAs.GreenBook, label: 'Green Book preset' },
  { id: UseSmileIDSampleCaptureAs.Passport, label: 'Passport preset' },
];
