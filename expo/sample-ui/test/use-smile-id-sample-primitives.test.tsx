import { UseSmileIDSampleAvatar } from '../src/components/use-smile-id-sample-avatar';
import { UseSmileIDSampleButton } from '../src/components/use-smile-id-sample-button';
import { UseSmileIDSampleSearchField } from '../src/components/use-smile-id-sample-search-field';
import { UseSmileIDSampleSectionLabel } from '../src/components/use-smile-id-sample-section-label';
import { UseSmileIDSampleStatusBadge } from '../src/components/use-smile-id-sample-status-badge';
import { UseSmileIDSampleSwitch } from '../src/components/use-smile-id-sample-switch';
import { UseSmileIDSampleTextInput } from '../src/components/use-smile-id-sample-text-input';
import { UseSmileIDSampleToast } from '../src/components/use-smile-id-sample-toast';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';
import { focusField, pressIn, schemes, type Interaction } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';

const noop = () => {};

/// Ids used only to drive a state that needs an interaction; the screens supply the real ones.
const BUTTON_ID = 'golden_button';
const FIELD_ID = 'golden_field';
const SEARCH_ID = 'golden_search';

/// One golden. `interact` is for the states a component only reaches under a finger or a caret.
type Case = { element: () => React.ReactElement; interact?: Interaction };

/// Every state each primitive declares in spec/components.json, so a missing state has no golden.
const cases: { component: string; states: Record<string, Case> }[] = [
  {
    component: 'Avatar',
    states: {
      initials: { element: () => <UseSmileIDSampleAvatar initials="KA" /> },
      placeholder: { element: () => <UseSmileIDSampleAvatar initials="" /> },
      // The profile row passes 44; the component's own default is 40 and would come out 4 short.
      row_size: { element: () => <UseSmileIDSampleAvatar initials="AD" size={44} /> },
    },
  },
  {
    component: 'Button',
    states: {
      enabled: { element: () => <UseSmileIDSampleButton text="Continue" onPress={noop} /> },
      disabled: { element: () => <UseSmileIDSampleButton text="Continue" onPress={noop} enabled={false} /> },
      loading: { element: () => <UseSmileIDSampleButton text="Continue" onPress={noop} loading /> },
      wrapping: {
        element: () => <UseSmileIDSampleButton text="Continue to the ID details form" onPress={noop} />,
      },
      pressed: {
        element: () => <UseSmileIDSampleButton text="Continue" onPress={noop} testID={BUTTON_ID} />,
        interact: pressIn(BUTTON_ID),
      },
    },
  },
  {
    component: 'TextInput',
    states: {
      empty: { element: () => <UseSmileIDSampleTextInput value="" onValueChange={noop} placeholder="ID number" /> },
      filled: { element: () => <UseSmileIDSampleTextInput value="1234567890" onValueChange={noop} /> },
      focused: {
        element: () => <UseSmileIDSampleTextInput value="1234" onValueChange={noop} testID={FIELD_ID} />,
        interact: focusField(FIELD_ID),
      },
      error: {
        element: () => (
          <UseSmileIDSampleTextInput
            value="12"
            onValueChange={noop}
            isError
            errorMessage="Enter a valid ID number"
          />
        ),
      },
      // Error outranks focus, so tapping back into a bad field must not hide the message.
      error_focused: {
        element: () => (
          <UseSmileIDSampleTextInput
            value="12"
            onValueChange={noop}
            isError
            errorMessage="Enter a valid ID number"
            testID={FIELD_ID}
          />
        ),
        interact: focusField(FIELD_ID),
      },
      disabled: { element: () => <UseSmileIDSampleTextInput value="1234" onValueChange={noop} enabled={false} /> },
      masked: { element: () => <UseSmileIDSampleTextInput value="9876543210" onValueChange={noop} masked /> },
      // A text input fills its column, so the alignment has to be set on the field itself.
      end_aligned: {
        element: () => <UseSmileIDSampleTextInput value="Ada Nwosu" onValueChange={noop} textAlign="right" />,
      },
    },
  },
  {
    component: 'SearchField',
    states: {
      empty: { element: () => <UseSmileIDSampleSearchField query="" onQueryChange={noop} placeholder="Search" /> },
      filled: { element: () => <UseSmileIDSampleSearchField query="Kenya" onQueryChange={noop} /> },
      focused: {
        element: () => <UseSmileIDSampleSearchField query="Ken" onQueryChange={noop} testID={SEARCH_ID} />,
        interact: focusField(SEARCH_ID),
      },
    },
  },
  {
    component: 'Switch',
    states: {
      on: { element: () => <UseSmileIDSampleSwitch checked onCheckedChange={noop} /> },
      off: { element: () => <UseSmileIDSampleSwitch checked={false} onCheckedChange={noop} /> },
      disabled_on: { element: () => <UseSmileIDSampleSwitch checked enabled={false} /> },
      disabled_off: { element: () => <UseSmileIDSampleSwitch checked={false} enabled={false} /> },
    },
  },
  {
    component: 'StatusBadge',
    states: {
      clear: { element: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Clear} /> },
      attention: { element: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Attention} /> },
      blocked: { element: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Blocked} /> },
      processing: { element: () => <UseSmileIDSampleStatusBadge status={UseSmileIDSampleStatus.Processing} /> },
    },
  },
  {
    component: 'SectionLabel',
    states: {
      default: { element: () => <UseSmileIDSampleSectionLabel text="AUTHENTICATION" /> },
    },
  },
  {
    component: 'Toast',
    states: {
      message: { element: () => <UseSmileIDSampleToast message="1 verification hidden from App list" /> },
      message_with_action: {
        element: () => (
          <UseSmileIDSampleToast
            message="1 verification hidden from App list"
            actionLabel="Undo"
            onAction={noop}
          />
        ),
      },
    },
  },
];

describe.each(cases)('$component', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      const entry = states[state]!;
      await expectGoldens(entry.element(), dark, { interact: entry.interact });
    });
  });
});

describe('golden coverage', () => {
  it('records both schemes for every state, which is what a dark-mode token defect shows up in', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(60);
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
