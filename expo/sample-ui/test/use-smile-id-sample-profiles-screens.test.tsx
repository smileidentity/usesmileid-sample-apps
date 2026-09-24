import { act, fireEvent } from '@testing-library/react-native';

import {
  UseSmileIDSampleTransientNoticeHost,
  useSmileIDSampleTransientNotice,
} from '../src/components/use-smile-id-sample-transient-notice';
import {
  NewProfileSheet,
  smileIDSampleNewProfileComplete,
  smileIDSampleNewProfileDraftEmpty,
  type UseSmileIDSampleNewProfileDraft,
} from '../src/screens/new-profile-sheet';
import { ProfileConfigScreen } from '../src/screens/profile-config-screen';
import { ProfileSwitchSheet } from '../src/screens/profile-switch-sheet';
import { ProfilesScreen } from '../src/screens/profiles-screen';
import { useSmileIDSampleProfileStore } from '../src/state/use-smile-id-sample-profile-store';
import {
  smileIDSampleEditorDefaults,
  smileIDSampleFixtureProfiles,
  smileIDSampleUserDetailsDefaults,
} from '../src/state/use-smile-id-sample-profiles';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { renderInTheme, schemes } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';

const noop = () => {};

const three = smileIDSampleFixtureProfiles();
const created = {
  id: 'p-4',
  organisation: 'Sahara Pay',
  person: 'Ngozi Eze',
  defaults: { ...smileIDSampleUserDetailsDefaults, firstName: 'Ngozi', lastName: 'Eze' },
};
const four = [...three, created];

const FILLED_DRAFT = {
  name: 'Sahara Pay',
  firstName: 'Ngozi',
  lastName: 'Eze',
  email: 'ngozi@saharapay.example',
  phone: '',
};

/// The created state is the list with its confirmation over it, which is how the route composes them.
const ProfilesWithNotice = () => {
  const notice = useSmileIDSampleTransientNotice();
  const { show } = notice;
  if (notice.current === null) {
    show({ message: `${created.organisation} created`, actionLabel: 'Make active', onAction: noop });
  }
  return (
    <>
      <ProfilesScreen
        state={{ profiles: four, activeId: 'p-1' }}
        onProfilePress={noop}
        onCreate={noop}
        onBack={noop}
      />
      <UseSmileIDSampleTransientNoticeHost state={notice} />
    </>
  );
};

type Case = { element: () => React.ReactElement };

const cases: { screen: string; states: Record<string, Case> }[] = [
  {
    screen: 'profiles',
    states: {
      default: {
        element: () => (
          <ProfilesScreen
            state={{ profiles: three, activeId: 'p-1' }}
            onProfilePress={noop}
            onCreate={noop}
            onBack={noop}
          />
        ),
      },
      created: { element: () => <ProfilesWithNotice /> },
    },
  },
  {
    screen: 'profileConfig',
    states: {
      // The CTA is the whole difference: disabled and renamed on the profile already active.
      activeProfile: {
        element: () => (
          <ProfileConfigScreen
            state={{
              organisation: 'UpTech Finance',
              defaults: three[0]!.defaults,
              isActive: true,
              callbackUrl: '',
              callbackOverride: null,
            }}
            onFieldChange={noop}
            onCallbackUrlChange={noop}
            onBack={noop}
            onSave={noop}
          />
        ),
      },
      otherProfile: {
        element: () => (
          <ProfileConfigScreen
            state={{
              organisation: 'Kazi Microlending',
              defaults: three[1]!.defaults,
              isActive: false,
              callbackUrl: '',
              callbackOverride: null,
            }}
            onFieldChange={noop}
            onCallbackUrlChange={noop}
            onBack={noop}
            onSave={noop}
          />
        ),
      },
      newlyCreated: {
        element: () => (
          <ProfileConfigScreen
            state={{
              organisation: created.organisation,
              defaults: created.defaults,
              isActive: false,
              callbackUrl: '',
              callbackOverride: null,
            }}
            onFieldChange={noop}
            onCallbackUrlChange={noop}
            onBack={noop}
            onSave={noop}
          />
        ),
      },
    },
  },
  {
    screen: 'newProfileSheet',
    states: {
      empty: {
        element: () => (
          <NewProfileSheet
            draft={smileIDSampleNewProfileDraftEmpty}
            onDraftChange={noop}
            onSave={noop}
            onDismiss={noop}
          />
        ),
      },
      filled: {
        element: () => (
          <NewProfileSheet
            draft={FILLED_DRAFT}
            onDraftChange={noop}
            onSave={noop}
            onDismiss={noop}
          />
        ),
      },
    },
  },
  {
    screen: 'profileSwitchSheet',
    states: {
      default: {
        element: () => (
          <ProfileSwitchSheet
            profiles={three}
            activeId="p-1"
            onSelect={noop}
            onDismiss={noop}
          />
        ),
      },
    },
  },
];

describe.each(cases)('$screen', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      await expectGoldens(states[state]!.element(), dark);
    });
  });
});

describe('profiles coverage', () => {
  it('records both schemes for every state', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(16);
  });
});

describe('the profiles list', () => {
  it('marks only the active row, so the list says which profile jobs run as', async () => {
    const rendered = await renderInTheme(
      <ProfilesScreen
        state={{ profiles: three, activeId: 'p-2' }}
        onProfilePress={noop}
        onCreate={noop}
        onBack={noop}
      />,
      false,
    );
    expect(rendered.queryByText('Amina Diallo · active')).not.toBeNull();
    expect(rendered.queryByText('Kwame Asante')).not.toBeNull();
    expect(rendered.queryByText('Kwame Asante · active')).toBeNull();
  });

  it('gives every row an id built from its profile id, which is what a flow taps', async () => {
    const rendered = await renderInTheme(
      <ProfilesScreen
        state={{ profiles: three, activeId: 'p-1' }}
        onProfilePress={noop}
        onCreate={noop}
        onBack={noop}
      />,
      false,
    );
    for (const profile of three) {
      expect(rendered.queryByTestId(`sample_profile_row_${profile.id}`)).not.toBeNull();
    }
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.CREATE_PROFILE)).not.toBeNull();
  });
});

describe('the new-profile sheet', () => {
  // Asserted on the CTA's own disabled state rather than by pressing it: the sheet's host view is
  // inert in a hostless runner, so a press proves nothing and "no call" would pass either way.
  const saveDisabled = async (draft: UseSmileIDSampleNewProfileDraft) => {
    const rendered = await renderInTheme(
      <NewProfileSheet draft={draft} onDraftChange={noop} onSave={noop} onDismiss={noop} />,
      false,
    );
    return rendered.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_SAVE).props.accessibilityState
      .disabled;
  };

  it('keeps the CTA disabled until name and both required names are present', async () => {
    expect(await saveDisabled(smileIDSampleNewProfileDraftEmpty)).toBe(true);
    expect(await saveDisabled({ ...smileIDSampleNewProfileDraftEmpty, name: 'Zuri Health' })).toBe(
      true,
    );
    expect(
      await saveDisabled({ ...FILLED_DRAFT, lastName: '' }),
    ).toBe(true);
  });

  it('enables it once the three are present, so a complete draft is not stranded', async () => {
    expect(await saveDisabled(FILLED_DRAFT)).toBe(false);
  });

  it('is not driveable by a press in this runner, which is why the CTA is asserted structurally', async () => {
    // Recorded rather than worked around: the sheet's host view reports pointerEvents=none in a hostless runner.
    const pressed: string[] = [];
    const rendered = await renderInTheme(
      <NewProfileSheet
        draft={FILLED_DRAFT}
        onDraftChange={noop}
        onSave={() => pressed.push('saved')}
        onDismiss={noop}
      />,
      false,
    );
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_SAVE));
    expect(pressed).toEqual([]);
  });

  it('treats blank space as absent, or a space would enable the CTA', () => {
    expect(smileIDSampleNewProfileComplete({ ...FILLED_DRAFT, name: '   ' })).toBe(false);
    expect(smileIDSampleNewProfileComplete(FILLED_DRAFT)).toBe(true);
  });

  it('reports the whole draft, so a partner keeps typing rather than losing a field', async () => {
    const drafts: string[] = [];
    const rendered = await renderInTheme(
      <NewProfileSheet
        draft={smileIDSampleNewProfileDraftEmpty}
        onDraftChange={(draft) => drafts.push(draft.email)}
        onSave={noop}
        onDismiss={noop}
      />,
      false,
    );
    await fireEvent.changeText(
      rendered.getByTestId(UseSmileIDSampleTestIds.NEW_PROFILE_EMAIL),
      'ada@zuri.example',
    );
    expect(drafts).toEqual(['ada@zuri.example']);
  });
});

describe('creating a profile', () => {
  beforeEach(() => {
    useSmileIDSampleProfileStore.getState().reset(smileIDSampleFixtureProfiles());
  });

  it('does not make it active, because the confirmation carries that offer instead', () => {
    const id = useSmileIDSampleProfileStore.getState().add('Zuri Health');
    expect(useSmileIDSampleProfileStore.getState().activeId).not.toBe(id);
    expect(useSmileIDSampleProfileStore.getState().lastCreatedId).toBe(id);
  });

  it('is announced once, so returning to the list cannot re-show the confirmation', () => {
    useSmileIDSampleProfileStore.getState().add('Zuri Health');
    useSmileIDSampleProfileStore.getState().clearLastCreated();
    expect(useSmileIDSampleProfileStore.getState().lastCreatedId).toBeNull();
  });
});

describe('the profile editor', () => {
  const stored = { ...smileIDSampleUserDetailsDefaults, firstName: 'Kwame', lastName: 'Asante' };
  const typed = { ...smileIDSampleUserDetailsDefaults, firstName: 'Ada' };

  it('shows a profile that arrives after the editor first rendered', () => {
    // The defect this guards: the route is deep-linkable, so a cold entry renders before the store holds the profile.
    expect(smileIDSampleEditorDefaults(null, 'p-1', undefined)).toEqual(
      smileIDSampleUserDetailsDefaults,
    );
    expect(smileIDSampleEditorDefaults(null, 'p-1', stored)).toEqual(stored);
  });

  it('keeps what the partner typed, even as the store changes underneath', () => {
    const edit = { profileId: 'p-1', details: typed };
    expect(smileIDSampleEditorDefaults(edit, 'p-1', stored)).toEqual(typed);
  });

  it('does not carry one profile\'s edit into another opened on the same route', () => {
    const edit = { profileId: 'p-1', details: typed };
    expect(smileIDSampleEditorDefaults(edit, 'p-2', stored)).toEqual(stored);
  });

  it('falls back to empty only when nothing is typed and nothing is stored', () => {
    expect(smileIDSampleEditorDefaults(null, undefined, undefined)).toEqual(
      smileIDSampleUserDetailsDefaults,
    );
  });
});

describe('the transient notice', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  const Host = ({ onAction }: { onAction?: () => void }) => {
    const notice = useSmileIDSampleTransientNotice();
    const { show } = notice;
    if (notice.current === null && notice.showToken === 0) {
      show({ message: 'Zuri Health created', actionLabel: 'Make active', onAction });
    }
    return <UseSmileIDSampleTransientNoticeHost state={notice} />;
  };

  it('dismisses itself, so a confirmation cannot outlive its cause', async () => {
    const rendered = await renderInTheme(<Host />, false);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.TOAST)).not.toBeNull();
    // Async, because a synchronous act does not flush the state update the timer schedules.
    await act(async () => {
      jest.advanceTimersByTime(5_000);
    });
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.TOAST)).toBeNull();
  });

  it('is still there a moment before the window closes, so the offer is actually reachable', async () => {
    const rendered = await renderInTheme(<Host />, false);
    await act(async () => {
      jest.advanceTimersByTime(4_900);
    });
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.TOAST)).not.toBeNull();
  });

  it('consumes the offer on action, so it cannot be taken twice', async () => {
    const taken: string[] = [];
    const rendered = await renderInTheme(<Host onAction={() => taken.push('active')} />, false);
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.TOAST_UNDO));
    expect(taken).toEqual(['active']);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.TOAST)).toBeNull();
  });
});
