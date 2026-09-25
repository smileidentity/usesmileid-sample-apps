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

/// Field by field, so key order never makes two equal sets of details read as different.
export const smileIDSampleUserDetailsEqual = (a: UseSmileIDSampleUserDetails, b: UseSmileIDSampleUserDetails): boolean =>
  a.firstName === b.firstName && a.lastName === b.lastName && a.email === b.email && a.phone === b.phone;

/// One persona a job runs as: the organisation the SDK's consent screen names, and the details its jobs carry.
export type UseSmileIDSampleProfile = {
  readonly id: string;
  /// May be blank, when consent names the app itself rather than the person being verified.
  readonly organisation: string;
  readonly defaults: UseSmileIDSampleUserDetails;
  /// The webhook URL this profile's jobs report to; absent or empty means the partner's portal default.
  readonly callbackUrl?: string;
};

/// The partner the consent screen names when no profile does.
export const USE_SMILE_ID_SAMPLE_NO_PROFILE_PARTNER_NAME = 'Smile ID';

/// What a plain launch has always sent as the partner id, so no profile changes nothing on the wire.
export const USE_SMILE_ID_SAMPLE_FIRST_PROFILE_ID = 'p-1';

/// What the header, settings card and form say while there is no profile.
export const USE_SMILE_ID_SAMPLE_NO_PROFILE_LABEL = 'No profile yet';

const NO_USER_DETAILS_CAPTION = 'No user details yet';

/// A profile naming neither an organisation nor a person, which only a token binding both names allows.
const UNNAMED_PROFILE = 'Unnamed profile';

/// The person the details name, so it can never disagree with them.
export const smileIDSampleProfilePerson = (profile: UseSmileIDSampleProfile): string =>
  `${profile.defaults.firstName} ${profile.defaults.lastName}`.trim();

/// What a row calls it: the organisation, or the person when it names none.
export const smileIDSampleProfileTitle = (profile: UseSmileIDSampleProfile): string =>
  profile.organisation.trim() || smileIDSampleProfilePerson(profile) || UNNAMED_PROFILE;

/// The person's initials, as the design has them, falling back to the organisation.
export const smileIDSampleProfileInitials = (profile: UseSmileIDSampleProfile): string => {
  const source = smileIDSampleProfilePerson(profile) || profile.organisation;
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
  smileIDSampleProfilePerson(profile) || NO_USER_DETAILS_CAPTION;

/// What the consent screen names as the partner: the app's own name when no profile names one.
export const smileIDSamplePartnerName = (profile: UseSmileIDSampleProfile | null): string =>
  profile?.organisation.trim() || USE_SMILE_ID_SAMPLE_NO_PROFILE_PARTNER_NAME;

/// The three the design's sheet shows. Reached only by the `seedProfiles` launch argument, and never stored.
export const smileIDSampleFixtureProfiles = (): readonly UseSmileIDSampleProfile[] => [
  {
    id: 'p-1',
    organisation: 'UpTech Finance',
    defaults: { ...smileIDSampleUserDetailsDefaults, firstName: 'Kwame', lastName: 'Asante' },
  },
  {
    id: 'p-2',
    organisation: 'Kazi Microlending',
    defaults: { ...smileIDSampleUserDetailsDefaults, firstName: 'Amina', lastName: 'Diallo' },
  },
  {
    id: 'p-3',
    organisation: 'PesaLink',
    defaults: { ...smileIDSampleUserDetailsDefaults, firstName: 'Tunde', lastName: 'Okafor' },
  },
];

/// What is stored: the profiles and which is active. Null `activeId` exactly when there are none.
export type UseSmileIDSampleProfilesRecord = {
  readonly profiles: readonly UseSmileIDSampleProfile[];
  readonly activeId: string | null;
};

/// A stored active id that names no profile falls back to the first; repeated ids keep the first.
export const smileIDSampleProfilesRecord = (
  profiles: readonly UseSmileIDSampleProfile[],
  activeId: string | null = null,
): UseSmileIDSampleProfilesRecord => {
  const seen = new Set<string>();
  const distinct = profiles.filter((profile) => !seen.has(profile.id) && seen.add(profile.id));
  const active = distinct.some((profile) => profile.id === activeId) ? activeId : (distinct[0]?.id ?? null);
  return { profiles: distinct, activeId: active };
};

const PROFILES_VERSION = 1;

const text = (value: unknown): string => (typeof value === 'string' ? value : '');

/// The stored form, one JSON value shared by all four apps so a record reads the same in each.
export const smileIDSampleEncodeProfiles = (record: UseSmileIDSampleProfilesRecord): string =>
  JSON.stringify({
    version: PROFILES_VERSION,
    activeId: record.activeId,
    profiles: record.profiles.map((profile) => ({
      id: profile.id,
      organisation: profile.organisation,
      firstName: profile.defaults.firstName,
      lastName: profile.defaults.lastName,
      email: profile.defaults.email,
      phone: profile.defaults.phone,
      callbackUrl: profile.callbackUrl ?? '',
    })),
  });

/// Anything unreadable, including a version this build does not know, is no profiles: never a crash.
export const smileIDSampleDecodeProfiles = (raw: string | null): UseSmileIDSampleProfilesRecord => {
  const none = smileIDSampleProfilesRecord([]);
  if (raw === null) return none;
  let root: unknown;
  try {
    root = JSON.parse(raw);
  } catch {
    return none;
  }
  if (typeof root !== 'object' || root === null || Array.isArray(root)) return none;
  const record = root as Record<string, unknown>;
  if (record.version !== PROFILES_VERSION || !Array.isArray(record.profiles)) return none;
  const profiles = record.profiles.flatMap((entry: unknown): UseSmileIDSampleProfile[] => {
    if (typeof entry !== 'object' || entry === null) return [];
    const row = entry as Record<string, unknown>;
    const id = text(row.id);
    if (id.trim().length === 0) return [];
    return [
      {
        id,
        organisation: text(row.organisation),
        defaults: {
          firstName: text(row.firstName),
          lastName: text(row.lastName),
          email: text(row.email),
          phone: text(row.phone),
        },
        callbackUrl: text(row.callbackUrl),
      },
    ];
  });
  return smileIDSampleProfilesRecord(profiles, typeof record.activeId === 'string' ? record.activeId : null);
};

/// What the partner has typed into a profile editor, and which profile they typed it into.
export type UseSmileIDSampleProfileEdit = {
  readonly profileId: string;
  readonly details: UseSmileIDSampleUserDetails;
};

/// Which values a profile editor shows: the typed ones, else the stored ones, else empty.
export const smileIDSampleEditorDefaults = (
  edit: UseSmileIDSampleProfileEdit | null,
  profileId: string | undefined,
  stored: UseSmileIDSampleUserDetails | undefined,
): UseSmileIDSampleUserDetails => {
  // Never captured at mount: a profile that arrives later must replace the empty form, or the CTA
  // writes that emptiness over stored defaults. An edit wins only for the profile it was typed into.
  if (edit !== null && profileId !== undefined && edit.profileId === profileId) return edit.details;
  return stored ?? smileIDSampleUserDetailsDefaults;
};
