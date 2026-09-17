import type { UseSmileIDSampleLaunchArgs } from './use-smile-id-sample-launch-args';

/// The fields the design labels "attached to every job", which is why every product collects them.
export type UseSmileIDSampleUserDetails = {
  readonly firstName: string;
  readonly lastName: string;
  readonly email: string;
  readonly phone: string;
};

export const smileIDSampleUserDetailsDefaults: UseSmileIDSampleUserDetails = {
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
};

/// One partner profile: who is signed in, and the defaults their jobs are seeded from.
export type UseSmileIDSampleProfile = {
  readonly id: string;
  readonly organisation: string;
  readonly person: string;
  readonly defaults: UseSmileIDSampleUserDetails;
};

/// Shown on the consent screen as the partner until a profile is created, so it must read as a placeholder.
export const USE_SMILE_ID_SAMPLE_STARTER_ORGANISATION = 'Default profile';

const NO_USER_DETAILS_CAPTION = 'No user details yet';

/// The person's initials, as the design has them, falling back to the organisation for a new profile.
export const smileIDSampleProfileInitials = (profile: UseSmileIDSampleProfile): string => {
  const source = profile.person.trim() || profile.organisation;
  const initials = source
    .split(' ')
    .filter((part) => part.trim().length > 0)
    .slice(0, 2)
    .map((part) => (part[0] ?? '').toUpperCase())
    .join('');
  return initials.length > 0 ? initials : '?';
};

/// What a row says under the organisation: the person, or a placeholder until details are saved.
export const smileIDSampleProfileCaption = (profile: UseSmileIDSampleProfile): string =>
  profile.person.trim() || NO_USER_DETAILS_CAPTION;

/// A plain launch: one empty profile, never the fixtures — the active organisation names the partner on the SDK's consent screen.
export const smileIDSampleStarterProfiles = (): readonly UseSmileIDSampleProfile[] => [
  {
    id: 'p-1',
    organisation: USE_SMILE_ID_SAMPLE_STARTER_ORGANISATION,
    person: '',
    defaults: smileIDSampleUserDetailsDefaults,
  },
];

/// The three the design's sheet shows. Reached only by the `seedProfiles` launch argument — see `spec/launch-args.json`.
export const smileIDSampleFixtureProfiles = (): readonly UseSmileIDSampleProfile[] => [
  {
    id: 'p-1',
    organisation: 'UpTech Finance',
    person: 'Kwame Asante',
    defaults: { ...smileIDSampleUserDetailsDefaults, firstName: 'Kwame', lastName: 'Asante' },
  },
  {
    id: 'p-2',
    organisation: 'Kazi Microlending',
    person: 'Amina Diallo',
    defaults: { ...smileIDSampleUserDetailsDefaults, firstName: 'Amina', lastName: 'Diallo' },
  },
  {
    id: 'p-3',
    organisation: 'PesaLink',
    person: 'Tunde Okafor',
    defaults: { ...smileIDSampleUserDetailsDefaults, firstName: 'Tunde', lastName: 'Okafor' },
  },
];

/// The fixtures only when `seedProfiles` asks, so the shell holds no choice a unit test cannot reach.
export const smileIDSampleProfilesForLaunch = (
  args: UseSmileIDSampleLaunchArgs,
): readonly UseSmileIDSampleProfile[] =>
  args.seedProfiles ? smileIDSampleFixtureProfiles() : smileIDSampleStarterProfiles();
