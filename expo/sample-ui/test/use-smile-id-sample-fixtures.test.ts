import { smileIDSampleLaunchArgsFrom } from '../src/state/use-smile-id-sample-launch-args';
import { useSmileIDSampleProfileStore } from '../src/state/use-smile-id-sample-profile-store';
import {
  USE_SMILE_ID_SAMPLE_STARTER_ORGANISATION,
  smileIDSampleFixtureProfiles,
  smileIDSampleProfileCaption,
  smileIDSampleProfileInitials,
  smileIDSampleProfilesForLaunch,
  smileIDSampleStarterProfiles,
} from '../src/state/use-smile-id-sample-profiles';

describe('the plain default', () => {
  it('is one empty starter profile, never the design fixtures', () => {
    const starter = smileIDSampleStarterProfiles();
    expect(starter).toHaveLength(1);
    expect(starter[0]?.organisation).toBe(USE_SMILE_ID_SAMPLE_STARTER_ORGANISATION);
    expect(starter[0]?.person).toBe('');
  });

  it('is what the store holds before any launch argument is read', () => {
    const state = useSmileIDSampleProfileStore.getState();
    expect(state.items.map((p) => p.organisation)).toEqual([USE_SMILE_ID_SAMPLE_STARTER_ORGANISATION]);
    expect(state.activeId).toBe('p-1');
    expect(state.lastCreatedId).toBeNull();
  });

  it('names no fixture organisation anywhere in the starter', () => {
    const fixtures = smileIDSampleFixtureProfiles().map((p) => p.organisation);
    const starter = smileIDSampleStarterProfiles().map((p) => p.organisation);
    expect(starter.filter((name) => fixtures.includes(name))).toEqual([]);
  });

  it('reads as a placeholder rather than a name, because the consent screen shows it as the partner', () => {
    const starter = smileIDSampleStarterProfiles()[0];
    expect(smileIDSampleProfileCaption(starter!)).toBe('No user details yet');
  });
});

describe('the launch choice', () => {
  it('keeps the starter when no argument asks for fixtures', () => {
    const args = smileIDSampleLaunchArgsFrom({});
    expect(smileIDSampleProfilesForLaunch(args)).toEqual(smileIDSampleStarterProfiles());
  });

  it('seeds the three design profiles only when seedProfiles asks', () => {
    const args = smileIDSampleLaunchArgsFrom({ seedProfiles: true });
    expect(smileIDSampleProfilesForLaunch(args).map((p) => p.organisation)).toEqual([
      'UpTech Finance',
      'Kazi Microlending',
      'PesaLink',
    ]);
  });
});

describe('the store', () => {
  afterEach(() => {
    useSmileIDSampleProfileStore.getState().reset(smileIDSampleStarterProfiles());
  });

  it('refuses an empty seed, which would surface far from here', () => {
    expect(() => useSmileIDSampleProfileStore.getState().reset([])).toThrow();
  });

  it('gives a created profile the first free id rather than one derived from the count', () => {
    const store = useSmileIDSampleProfileStore.getState();
    store.reset(smileIDSampleFixtureProfiles());
    expect(useSmileIDSampleProfileStore.getState().add('Zenith Bank', 'Ada Nwosu')).toBe('p-4');
  });

  it('ignores a request to activate a profile it does not hold', () => {
    useSmileIDSampleProfileStore.getState().setActive('p-99');
    expect(useSmileIDSampleProfileStore.getState().activeId).toBe('p-1');
  });

  it('names the starter from its saved details, and leaves a created name alone', () => {
    const store = useSmileIDSampleProfileStore.getState();
    store.setDefaults('p-1', { firstName: 'Ada', lastName: 'Nwosu', email: '', phone: '' });
    expect(useSmileIDSampleProfileStore.getState().items[0]?.person).toBe('Ada Nwosu');
  });
});

describe('initials', () => {
  const profile = (person: string, organisation = 'UpTech Finance') => ({
    id: 'p-1',
    organisation,
    person,
    defaults: { firstName: '', lastName: '', email: '', phone: '' },
  });

  it('takes the first two words of the person', () => {
    expect(smileIDSampleProfileInitials(profile('Kwame Asante'))).toBe('KA');
  });

  it('falls back to the organisation for a profile with no person yet', () => {
    expect(smileIDSampleProfileInitials(profile(''))).toBe('UF');
  });

  it('never returns an empty string, which would draw an avatar with nothing in it', () => {
    expect(smileIDSampleProfileInitials(profile('', '   '))).toBe('?');
  });
});
