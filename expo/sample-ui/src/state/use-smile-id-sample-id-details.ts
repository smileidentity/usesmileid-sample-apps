/// A country the sandbox supports, with the flag the picker leads each row with.
export type UseSmileIDSampleCountry = {
  readonly code: string;
  readonly label: string;
  readonly flag: string;
};

export const smileIDSampleCountries: readonly UseSmileIDSampleCountry[] = [
  { code: 'NG', label: 'Nigeria', flag: '🇳🇬' },
  { code: 'KE', label: 'Kenya', flag: '🇰🇪' },
  { code: 'GH', label: 'Ghana', flag: '🇬🇭' },
  { code: 'ZA', label: 'South Africa', flag: '🇿🇦' },
  { code: 'UG', label: 'Uganda', flag: '🇺🇬' },
  { code: 'TZ', label: 'Tanzania', flag: '🇹🇿' },
  { code: 'RW', label: 'Rwanda', flag: '🇷🇼' },
];

const ALL_COUNTRIES = smileIDSampleCountries.map((country) => country.code);

/// An ID type and the countries it applies to, which is why the trigger is disabled without one.
export type UseSmileIDSampleIdType = {
  readonly id: string;
  readonly label: string;
  readonly countries: readonly string[];
};

export const smileIDSampleIdTypes: readonly UseSmileIDSampleIdType[] = [
  { id: 'NATIONAL_ID', label: 'National ID', countries: ALL_COUNTRIES },
  { id: 'PASSPORT', label: 'Passport', countries: ALL_COUNTRIES },
  { id: 'DRIVERS_LICENSE', label: "Driver's licence", countries: ['NG', 'KE', 'ZA'] },
  { id: 'VOTER_ID', label: 'Voter ID', countries: ['NG', 'GH'] },
];

/// The types a country offers. Empty without a country, which is the disabled trigger's reason.
export const smileIDSampleIdTypesFor = (
  country: UseSmileIDSampleCountry | null,
): readonly UseSmileIDSampleIdType[] =>
  country === null ? [] : smileIDSampleIdTypes.filter((type) => type.countries.includes(country.code));

export const smileIDSampleCountryFrom = (code: string | null | undefined) =>
  smileIDSampleCountries.find((country) => country.code === code) ?? null;

export const smileIDSampleIdTypeFrom = (id: string | null | undefined) =>
  smileIDSampleIdTypes.find((type) => type.id === id) ?? null;

/// The ID-details form. ID type stays unselectable until a country is chosen.
export type UseSmileIDSampleIdDetails = {
  readonly country: UseSmileIDSampleCountry | null;
  readonly idType: UseSmileIDSampleIdType | null;
  readonly idNumber: string;
};

export const smileIDSampleIdDetailsDefaults: UseSmileIDSampleIdDetails = {
  country: null,
  idType: null,
  idNumber: '',
};

export const smileIDSampleIdDetailsComplete = (details: UseSmileIDSampleIdDetails): boolean =>
  details.country !== null && details.idType !== null && details.idNumber.trim().length > 0;

/// Matches on the label, which is what the search field shows, case-folded so a lowercase query still hits.
export const smileIDSampleOptionMatches = (label: string, query: string): boolean =>
  label.toLowerCase().includes(query.trim().toLowerCase());
