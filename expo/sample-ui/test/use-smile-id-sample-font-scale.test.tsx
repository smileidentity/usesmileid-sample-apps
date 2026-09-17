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
import { DESIGN_FONT_SCALE, ENLARGED_FONT_SCALE, schemes, styleTree } from './render-in-theme';

const noop = () => {};
const product = smileIDSampleProducts[0]!;

/// The states whose LAYOUT changes with the font scale, which is why they need a second baseline:
/// a row that reflows, a title that wraps, a control that grows. Everything else is covered once.
const scaleSensitive: Record<string, () => React.ReactElement> = {
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

describe.each(schemes)('at the largest content size, $name', ({ dark }) => {
  it.each(Object.keys(scaleSensitive))('%s', async (state) => {
    const tree = await styleTree(scaleSensitive[state]!(), dark, undefined, ENLARGED_FONT_SCALE);
    expect(tree).toMatchSnapshot();
  });
});

const treeText = async (element: React.ReactElement, fontScale: number) =>
  JSON.stringify(await styleTree(element, false, undefined, fontScale));

describe('nothing that promises to wrap ellipsises instead', () => {
  it('lets the job row reflow rather than keeping its one-line cap', async () => {
    // At the design's scale both text lines are capped at one line so every row is the same height;
    // at enlarged type the cap has to come off, or the title clips instead of wrapping.
    const design = await treeText(scaleSensitive.job_row!(), DESIGN_FONT_SCALE);
    const enlarged = await treeText(scaleSensitive.job_row!(), ENLARGED_FONT_SCALE);
    expect(design).toContain('"numberOfLines":1');
    expect(enlarged).not.toContain('"numberOfLines":1');
  });

  it('never caps a line count anywhere else, at either scale', async () => {
    for (const [state, element] of Object.entries(scaleSensitive)) {
      if (state === 'job_row') continue;
      for (const scale of [DESIGN_FONT_SCALE, ENLARGED_FONT_SCALE]) {
        const tree = await treeText(element(), scale);
        // The toast's action is the one deliberate single-line node, and it widens rather than clips.
        const caps = (tree.match(/"numberOfLines":1/g) ?? []).length;
        expect({ state, scale, caps }).toEqual({
          state,
          scale,
          caps: state === 'toast_with_action' ? 1 : 0,
        });
      }
    }
  });
});

describe('a control that must grow with the scale does', () => {
  it('scales the avatar, because wrapping its initials renders an ellipse', async () => {
    const design = await treeText(scaleSensitive.avatar!(), DESIGN_FONT_SCALE);
    const enlarged = await treeText(scaleSensitive.avatar!(), ENLARGED_FONT_SCALE);
    expect(design).toContain('"width":40');
    expect(enlarged).toContain('"width":80');
  });

  it('scales the app bar row, so the header does not sit lower on one screen than another', async () => {
    const design = await treeText(scaleSensitive.top_app_bar_wrapping_title!(), DESIGN_FONT_SCALE);
    const enlarged = await treeText(scaleSensitive.top_app_bar_wrapping_title!(), ENLARGED_FONT_SCALE);
    expect(design).toContain('"minHeight":40');
    expect(enlarged).toContain('"minHeight":80');
  });
});

describe('font-scale coverage', () => {
  it('records both schemes for every scale-sensitive state', () => {
    expect(Object.keys(scaleSensitive).length * schemes.length).toBe(18);
  });
});
