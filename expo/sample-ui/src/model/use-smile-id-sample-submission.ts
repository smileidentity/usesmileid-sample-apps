import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// config.skipApiSubmission, in `spec/test-ids.json`'s vocabulary: skip hands the captured job back instead of submitting it.
export const UseSmileIDSampleSubmission = {
  Submit: 'submit',
  Skip: 'skip',
} as const;

export type UseSmileIDSampleSubmission =
  (typeof UseSmileIDSampleSubmission)[keyof typeof UseSmileIDSampleSubmission];

/// The sheet's rows in order, with what each and the Settings line say.
export const smileIDSampleSubmissions: readonly {
  readonly id: UseSmileIDSampleSubmission;
  readonly label: (strings: UseSmileIDSampleStrings) => string;
}[] = [
  { id: UseSmileIDSampleSubmission.Submit, label: (strings) => strings.submissionSubmit },
  { id: UseSmileIDSampleSubmission.Skip, label: (strings) => strings.submissionSkip },
];

/// What the Settings line says for `submission`.
export const smileIDSampleSubmissionLabel = (
  submission: UseSmileIDSampleSubmission,
  strings: UseSmileIDSampleStrings,
): string => smileIDSampleSubmissions.find((it) => it.id === submission)?.label(strings) ?? submission;

/// What the flow's config.skipApiSubmission is set to.
export const smileIDSampleSkipsApiSubmission = (submission: UseSmileIDSampleSubmission): boolean =>
  submission === UseSmileIDSampleSubmission.Skip;
