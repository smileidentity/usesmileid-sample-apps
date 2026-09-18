import { UseSmileIDSampleAvatar } from '../src/components/use-smile-id-sample-avatar';
import { UseSmileIDSampleButton } from '../src/components/use-smile-id-sample-button';
import { UseSmileIDSampleDataFieldRow } from '../src/components/use-smile-id-sample-data-field-row';
import { UseSmileIDSampleFilterChip } from '../src/components/use-smile-id-sample-filter-chip';
import { UseSmileIDSampleJobRow } from '../src/components/use-smile-id-sample-job-row';
import { UseSmileIDSampleKeyValueEditRow } from '../src/components/use-smile-id-sample-key-value-edit-row';
import { UseSmileIDSampleSelectionBar } from '../src/components/use-smile-id-sample-selection-bar';
import { UseSmileIDSampleToast } from '../src/components/use-smile-id-sample-toast';
import { UseSmileIDSampleTopAppBar } from '../src/components/use-smile-id-sample-top-app-bar';
import { smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';

const noop = () => {};
const product = smileIDSampleProducts[0]!;

/// The states whose LAYOUT changes with the font scale, so each needs a second baseline; the rest are covered once.
export const scaleSensitive: Record<string, () => React.ReactElement> = {
  avatar: () => <UseSmileIDSampleAvatar initials="KA" />,
  button_wrapping: () => (
    <UseSmileIDSampleButton text="Continue to the ID details form" onPress={noop} />
  ),
  top_app_bar_wrapping_title: () => (
    <UseSmileIDSampleTopAppBar title="Enhanced Document Verification" onBack={noop} />
  ),
  data_field_row_with_copy: () => (
    <UseSmileIDSampleDataFieldRow label="Job_id" value="7d2f01aa-4b1c" onCopy={noop} />
  ),
  key_value_edit_row: () => (
    <UseSmileIDSampleKeyValueEditRow label="First name" value="Ada" onValueChange={noop} />
  ),
  filter_chip: () => (
    <UseSmileIDSampleFilterChip label="Attention" count={2} selected={false} onPress={noop} />
  ),
  job_row: () => (
    <UseSmileIDSampleJobRow
      product={product}
      jobId="7d2f01aa…"
      time="13:03:41"
      status={UseSmileIDSampleStatus.Clear}
    />
  ),
  selection_bar: () => <UseSmileIDSampleSelectionBar selectedCount={3} onRemove={noop} />,
  toast_with_action: () => (
    <UseSmileIDSampleToast
      message="1 verification hidden from App list"
      actionLabel="Undo"
      onAction={noop}
    />
  ),
};
