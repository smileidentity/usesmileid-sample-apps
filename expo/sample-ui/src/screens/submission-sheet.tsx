import { UseSmileIDSampleBottomSheet } from '../components/use-smile-id-sample-bottom-sheet';
import { UseSmileIDSampleOptionRow } from '../components/use-smile-id-sample-option-row';
import { smileIDSampleSubmissions, type UseSmileIDSampleSubmission } from '../model/use-smile-id-sample-submission';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleStrings } from '../use-smile-id-sample-strings-context';

type Props = {
  selected: UseSmileIDSampleSubmission;
  onSelect: (submission: UseSmileIDSampleSubmission) => void;
  onDismiss: () => void;
};

/// config.skipApiSubmission's two values: submit the job, or hand the captured job back.
export const SubmissionSheet = ({ selected, onSelect, onDismiss }: Props) => {
  const strings = useSmileIDSampleStrings();
  return (
    <UseSmileIDSampleBottomSheet
      title={strings.submissionTitle}
      onDismiss={onDismiss}
      testID={UseSmileIDSampleTestIds.SUBMISSION_SHEET}
    >
      {smileIDSampleSubmissions.map((submission) => (
        <UseSmileIDSampleOptionRow
          key={submission.id}
          label={submission.label(strings)}
          selected={submission.id === selected}
          onPress={() => onSelect(submission.id)}
          testID={UseSmileIDSampleSuffixedTestIds.submissionOption(submission.id)}
        />
      ))}
    </UseSmileIDSampleBottomSheet>
  );
};
