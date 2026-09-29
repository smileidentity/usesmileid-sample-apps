/// How the SDK photographs the chosen document, each the SDK's own type; never what the server receives.
export const UseSmileIDSampleCaptureAs = {
  GenericDocument: 'genericDocument',
  GreenBook: 'greenBook',
  Passport: 'passport',
} as const;

export type UseSmileIDSampleCaptureAs = (typeof UseSmileIDSampleCaptureAs)[keyof typeof UseSmileIDSampleCaptureAs];

/// The sheet's first row, which clears the override so the document decides.
export const smileIDSampleMatchDocumentId = 'matchDocument';

/// The Match row's name and the trigger's placeholder.
export const smileIDSampleMatchDocumentLabel = 'Match document';

/// What a preset or Generic document is called on the sheet and the trigger.
export const smileIDSampleCaptureAsLabel = (captureAs: UseSmileIDSampleCaptureAs): string =>
  smileIDSampleCaptureAsOptions.find((option) => option.id === captureAs)?.label ?? captureAs;

/// The override rows the capture-as sheet offers under Match document, in its order, with what each says.
export const smileIDSampleCaptureAsOptions: readonly {
  readonly id: UseSmileIDSampleCaptureAs;
  readonly label: string;
}[] = [
  { id: UseSmileIDSampleCaptureAs.GenericDocument, label: 'Generic document' },
  { id: UseSmileIDSampleCaptureAs.GreenBook, label: 'Green Book preset' },
  { id: UseSmileIDSampleCaptureAs.Passport, label: 'Passport preset' },
];
