import { UseSmileIDSampleAvatar } from '../src/components/use-smile-id-sample-avatar';
import { UseSmileIDSampleButton } from '../src/components/use-smile-id-sample-button';
import { UseSmileIDSampleSearchField } from '../src/components/use-smile-id-sample-search-field';
import { UseSmileIDSampleSectionLabel } from '../src/components/use-smile-id-sample-section-label';
import { UseSmileIDSampleStatusBadge } from '../src/components/use-smile-id-sample-status-badge';
import { UseSmileIDSampleSwitch } from '../src/components/use-smile-id-sample-switch';
import { UseSmileIDSampleTextInput } from '../src/components/use-smile-id-sample-text-input';
import { UseSmileIDSampleToast } from '../src/components/use-smile-id-sample-toast';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import { schemes, styleTree } from './render-in-theme';

const noop = () => {};

/// Every state each primitive declares in spec/components.json, so a missing state has no golden.
const cases: { component: string; states: Record<string, () => React.ReactElement> }[] = [
  {
    component: 'Avatar',
    states: {
      initials: () => <UseSmileIDSampleAvatar initials="KA" />,
      placeholder: () => <UseSmileIDSampleAvatar initials="" />,
      // The profile row passes 44; the component's own default is 40 and would come out 4 short.
      row_size: () => <UseSmileIDSampleAvatar initials="AD" size={44} />,
    },
  },
  {
    component: 'Button',
    states: {
      enabled: () => <UseSmileIDSampleButton text="Continue" onPress={noop} />,
      disabled: () => <UseSmileIDSampleButton text="Continue" onPress={noop} enabled={false} />,
      loading: () => <UseSmileIDSampleButton text="Continue" onPress={noop} loading />,
      wrapping: () => (
        <UseSmileIDSampleButton text="Continue to the ID details form" onPress={noop} />
      ),
    },
  },
  {
    component: 'TextInput',
    states: {
      empty: () => <UseSmileIDSampleTextInput value="" onValueChange={noop} placeholder="ID number" />,
      filled: () => <UseSmileIDSampleTextInput value="1234567890" onValueChange={noop} />,
      error: () => (
        <UseSmileIDSampleTextInput
          value="12"
          onValueChange={noop}
          isError
          errorMessage="Enter a valid ID number"
        />
      ),
      disabled: () => <UseSmileIDSampleTextInput value="1234" onValueChange={noop} enabled={false} />,
      masked: () => <UseSmileIDSampleTextInput value="9876543210" onValueChange={noop} masked />,
      // A text input fills its column, so the alignment has to be set on the field itself.
      end_aligned: () => (
        <UseSmileIDSampleTextInput value="Ada Nwosu" onValueChange={noop} textAlign="right" />
      ),
    },
  },
  {
    component: 'SearchField',
    states: {
      empty: () => <UseSmileIDSampleSearchField query="" onQueryChange={noop} placeholder="Search" />,
      filled: () => <UseSmileIDSampleSearchField query="Kenya" onQueryChange={noop} />,
    },
  },
  {
    component: 'Switch',
    states: {
      on: () => <UseSmileIDSampleSwitch checked onCheckedChange={noop} />,
      off: () => <UseSmileIDSampleSwitch checked={false} onCheckedChange={noop} />,
      disabled_on: () => <UseSmileIDSampleSwitch checked enabled={false} />,
      disabled_off: () => <UseSmileIDSampleSwitch checked={false} enabled={false} />,
    },
  },
  {
    component: 'StatusBadge',
    states: {
      clear: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Clear} />,
      attention: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Attention} />,
      blocked: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Blocked} />,
      processing: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Processing} />,
    },
  },
  {
    component: 'SectionLabel',
    states: {
      default: () => <UseSmileIDSampleSectionLabel text="AUTHENTICATION" />,
    },
  },
  {
    component: 'Toast',
    states: {
      message: () => <UseSmileIDSampleToast message="1 verification hidden from App list" />,
      message_with_action: () => (
        <UseSmileIDSampleToast
          message="1 verification hidden from App list"
          actionLabel="Undo"
          onAction={noop}
        />
      ),
    },
  },
];

describe.each(cases)('$component', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      expect(await styleTree(states[state]!(), dark)).toMatchSnapshot();
    });
  });
});

describe('golden coverage', () => {
  it('records both schemes for every state, which is what a dark-mode token defect shows up in', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(52);
  });

  it('covers all eight U1 primitives', () => {
    expect(cases.map((entry) => entry.component)).toEqual([
      'Avatar',
      'Button',
      'TextInput',
      'SearchField',
      'Switch',
      'StatusBadge',
      'SectionLabel',
      'Toast',
    ]);
  });
});
