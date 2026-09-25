import AsyncStorage from '@react-native-async-storage/async-storage';

import { smileIDSampleLaunchArgsFrom } from '../src/state/use-smile-id-sample-launch-args';
import {
  SMILE_ID_SAMPLE_PROFILES_KEY,
  useSmileIDSampleProfileStore,
} from '../src/state/use-smile-id-sample-profile-store';
import {
  smileIDSampleDecodeProfiles,
  smileIDSampleEncodeProfiles,
  smileIDSampleFixtureProfiles,
  smileIDSamplePartnerName,
  smileIDSampleProfileCaption,
  smileIDSampleProfileInitials,
  smileIDSampleProfileTitle,
  smileIDSampleProfilesRecord,
  type UseSmileIDSampleProfile,
} from '../src/state/use-smile-id-sample-profiles';

const store = () => useSmileIDSampleProfileStore.getState();
const ada = { firstName: 'Ada', lastName: 'Okafor', email: 'ada@kobo.example', phone: '' };
const noDetails = { firstName: '', lastName: '', email: '', phone: '' };
/// The store chains its writes behind one another, so a few macrotasks drain the chain.
const settle = async () => {
  for (let turn = 0; turn < 5; turn += 1) await new Promise((resolve) => setTimeout(resolve, 0));
};
const stored = async () => smileIDSampleDecodeProfiles(await AsyncStorage.getItem(SMILE_ID_SAMPLE_PROFILES_KEY));

const profile = (organisation: string, firstName = '', lastName = ''): UseSmileIDSampleProfile => ({
  id: 'p-1',
  organisation,
  defaults: { ...noDetails, firstName, lastName },
});

/// Back to a process that has not read the store yet.
const relaunch = () => useSmileIDSampleProfileStore.setState({ items: [], activeId: null, loaded: false, seeded: false });

beforeEach(async () => {
  // A write the last test left queued would otherwise land in this one.
  await settle();
  await AsyncStorage.clear();
  relaunch();
  await store().load(smileIDSampleLaunchArgsFrom({}));
});

describe('a launch', () => {
  it('with no arguments has no profile, and consent names the app', () => {
    expect(store().items).toEqual([]);
    expect(store().activeId).toBeNull();
    expect(store().loaded).toBe(true);
    expect(smileIDSamplePartnerName(null)).toBe('Smile ID');
  });

  it('seeds the three design profiles only when seedProfiles asks, and stores nothing', async () => {
    relaunch();
    await store().load(smileIDSampleLaunchArgsFrom({ seedProfiles: true }));
    store().add('Karibu Pay');
    store().setActive('p-2');
    await settle();

    expect(store().items.map((p) => p.organisation)).toEqual([
      'UpTech Finance',
      'Kazi Microlending',
      'PesaLink',
      'Karibu Pay',
    ]);
    expect(await AsyncStorage.getItem(SMILE_ID_SAMPLE_PROFILES_KEY)).toBeNull();
  });

  it('reads what an earlier process stored', async () => {
    store().add('Kobo Bank', ada);
    await settle();
    relaunch();

    await store().load(smileIDSampleLaunchArgsFrom({}));

    expect(store().items.map((p) => p.organisation)).toEqual(['Kobo Bank']);
    expect(store().activeId).toBe('p-1');
  });

  it('from an install holding only the released keys reads as no profiles', async () => {
    await AsyncStorage.setItem('sample.setting.darkMode', 'true');
    relaunch();

    await store().load(smileIDSampleLaunchArgsFrom({}));

    expect(store().items).toEqual([]);
  });
});

describe('the store', () => {
  it('reads the store once per launch, so a remount keeps the profiles in use', async () => {
    store().add('Kobo Bank');
    await AsyncStorage.clear();

    await store().load(smileIDSampleLaunchArgsFrom({}));

    expect(store().items.map((p) => p.organisation)).toEqual(['Kobo Bank']);
  });

  it('writes nothing for an update that changes nothing', async () => {
    const id = store().add('Kobo Bank', ada);
    // The mock's own record, not a spy: restoring a spy on a jest.fn would wipe its implementation.
    const setItem = AsyncStorage.setItem as jest.Mock;
    await settle();
    const before = setItem.mock.calls.length;

    store().update(id, { organisation: 'Kobo Bank', defaults: { ...ada } });
    await settle();

    expect(setItem.mock.calls.length).toBe(before);
  });

  it('makes the first profile active, and leaves later ones for the offer', () => {
    const first = store().add('Karibu Pay');
    expect(store().activeId).toBe(first);
    expect(store().lastCreatedId).toBeNull();

    const second = store().add('Sahara Pay');
    expect(store().activeId).toBe(first);
    expect(store().lastCreatedId).toBe(second);
  });

  it('gives a created profile the first free id rather than one derived from the count', () => {
    store().reset(smileIDSampleFixtureProfiles());
    expect(store().add('Zenith Bank')).toBe('p-4');
  });

  it('ignores a request to activate a profile it does not hold', () => {
    store().reset(smileIDSampleFixtureProfiles());
    store().setActive('p-99');
    expect(store().activeId).toBe('p-1');
  });

  it('leaves what an update was not given', () => {
    const id = store().add('Karibu Pay');
    store().update(id, { callbackUrl: ' https://partner.example/hook ' });
    store().update(id, { defaults: ada });

    const [saved] = store().items;
    expect(saved?.callbackUrl).toBe('https://partner.example/hook');
    expect(saved?.organisation).toBe('Karibu Pay');
  });

  it('hands over to the first profile left when the active one is deleted, then to none', () => {
    store().reset(smileIDSampleFixtureProfiles(), 'p-2');
    store().delete('p-2');
    expect(store().activeId).toBe('p-1');

    store().delete('p-1');
    store().delete('p-3');
    expect(store().activeId).toBeNull();
  });

  it('deletes the stored profiles on a sign-out from a seeded launch', async () => {
    store().add('Kobo Bank', ada);
    await settle();
    relaunch();
    await store().load(smileIDSampleLaunchArgsFrom({ seedProfiles: true }));

    store().clear();
    await settle();

    expect((await stored()).profiles).toEqual([]);
  });

  it('stores sign-out as no profiles', async () => {
    store().add('Kobo Bank', ada);
    store().clear();
    await settle();

    expect((await stored()).profiles).toEqual([]);
  });
});

describe('keep', () => {
  it('makes the first run an active profile from what was typed', async () => {
    store().keep(ada, ' Kobo Bank ');
    await settle();

    expect(store().items[0]?.organisation).toBe('Kobo Bank');
    expect((await stored()).profiles[0]?.defaults).toEqual(ada);
  });

  it('writes an active profile the edits', () => {
    store().reset(smileIDSampleFixtureProfiles());
    store().keep(ada, '');

    expect(store().items[0]?.defaults).toEqual(ada);
    expect(store().items[0]?.organisation).toBe('UpTech Finance');
    expect(store().items).toHaveLength(3);
  });

  it('never stores a field the token supplies', () => {
    store().reset([profile('UpTech', 'Kwame', 'Asante')]);
    store().keep({ ...noDetails, email: 'ada@kobo.example' }, '', {
      firstName: false,
      lastName: false,
      contact: true,
    });

    expect(store().items[0]?.defaults).toEqual({ ...noDetails, firstName: 'Kwame', lastName: 'Asante', email: 'ada@kobo.example' });
  });
});

describe('the stored record', () => {
  it('round-trips, including characters JSON escapes', () => {
    const record = smileIDSampleProfilesRecord(
      [
        {
          id: 'p-1',
          organisation: 'Kobo "Bank" \\ Ltd\n',
          defaults: { firstName: 'Adá', lastName: "O'Neil", email: 'ada@kobo.example', phone: '+254 700' },
          callbackUrl: 'https://kobo.example/hook?a=1&b=2',
        },
        { id: 'p-2', organisation: '', defaults: noDetails, callbackUrl: '' },
      ],
      'p-2',
    );

    expect(smileIDSampleDecodeProfiles(smileIDSampleEncodeProfiles(record))).toEqual(record);
  });

  it('reads anything unreadable as no profiles', () => {
    for (const raw of [
      null,
      '',
      'not json',
      '[]',
      '{"profiles":[{"id":"p-1"}]}',
      '{"version":2,"profiles":[{"id":"p-1"}]}',
      '{"version":1,"profiles":"p-1"}',
      '{"version":1,"profiles":[{"id":"p-1","organisation":"Kobo"',
    ]) {
      expect(smileIDSampleDecodeProfiles(raw).profiles).toEqual([]);
    }
  });

  it('drops a profile without an id, and a repeated one', () => {
    const decoded = smileIDSampleDecodeProfiles(
      '{"version":1,"activeId":"p-1","profiles":[{"organisation":"No id"},{"id":"p-1","organisation":"First"},{"id":"p-1","organisation":"Again"}]}',
    );

    expect(decoded.profiles.map((p) => p.organisation)).toEqual(['First']);
  });

  it('falls back to the first profile for a stored active id that names none', () => {
    expect(smileIDSampleProfilesRecord(smileIDSampleFixtureProfiles(), 'p-9').activeId).toBe('p-1');
  });
});

describe('a profile', () => {
  it('names the app on consent when its organisation is blank, never the person', () => {
    const person = profile('', 'Ada', 'Okafor');
    expect(smileIDSampleProfileTitle(person)).toBe('Ada Okafor');
    expect(smileIDSamplePartnerName(person)).toBe('Smile ID');
  });

  it('takes its initials from the person, then the organisation', () => {
    expect(smileIDSampleProfileInitials(profile('UpTech Finance', 'Kwame', 'Asante'))).toBe('KA');
    expect(smileIDSampleProfileInitials(profile('UpTech Finance'))).toBe('UF');
    expect(smileIDSampleProfileInitials(profile('   '))).toBe('?');
  });

  it('says so under the organisation until details are saved', () => {
    expect(smileIDSampleProfileCaption(profile('Kobo Bank'))).toBe('No user details yet');
  });
});
