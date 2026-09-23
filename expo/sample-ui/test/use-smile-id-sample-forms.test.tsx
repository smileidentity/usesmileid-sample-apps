import { fireEvent } from '@testing-library/react-native';

import {
  smileIDSampleCountries,
  smileIDSampleIdDetailsComplete,
  smileIDSampleIdDetailsDefaults,
  smileIDSampleIdTypes,
  smileIDSampleIdTypesFor,
  smileIDSampleOptionMatches,
} from '../src/state/use-smile-id-sample-id-details';
import { useSmileIDSampleFormsStore } from '../src/state/use-smile-id-sample-forms-store';
import {
  smileIDSampleDetailsSatisfy,
  smileIDSampleRequirementDefaults,
  smileIDSampleRequirementFrom,
  smileIDSampleRequirementLabel,
  smileIDSampleRequirementPrompt,
  smileIDSampleRequirementSatisfied,
  smileIDSampleRequirementSupplies,
} from '../src/state/use-smile-id-sample-user-details-requirement';
import {
  UseSmileIDSampleUserField,
  smileIDSampleUserFields,
} from '../src/model/use-smile-id-sample-user-fields';
import { CountryPickerSheet } from '../src/screens/country-picker-sheet';
import { IdTypePickerSheet } from '../src/screens/id-type-picker-sheet';
import { KycIdFormScreen } from '../src/screens/kyc-id-form-screen';
import { UserDetailsScreen } from '../src/screens/user-details-screen';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { focusField, renderInTheme, schemes, styleTree } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';

const noop = () => {};

const NIGERIA = smileIDSampleCountries[0]!;
const KENYA = smileIDSampleCountries[1]!;
const UGANDA = smileIDSampleCountries.find((country) => country.code === 'UG')!;
const NATIONAL_ID = smileIDSampleIdTypes[0]!;

const EMPTY_DETAILS = { firstName: '', lastName: '', email: '', phone: '' };
const FILLED_DETAILS = {
  firstName: 'Kwame',
  lastName: 'Asante',
  email: 'kwame@uptech.example',
  phone: '+254 700 000 000',
};

const userDetails = (
  overrides: Partial<Parameters<typeof UserDetailsScreen>[0]> = {},
): React.ReactElement => (
  <UserDetailsScreen
    state={{ productLabel: 'Biometric KYC', details: EMPTY_DETAILS, rememberDetails: true }}
    onFieldChange={noop}
    onRememberChange={noop}
    onBack={noop}
    onContinue={noop}
    {...overrides}
  />
);

const kycForm = (
  overrides: Partial<Parameters<typeof KycIdFormScreen>[0]> = {},
): React.ReactElement => (
  <KycIdFormScreen
    state={{ productLabel: 'Biometric KYC', details: smileIDSampleIdDetailsDefaults }}
    onCountryPress={noop}
    onIdTypePress={noop}
    onIdNumberChange={noop}
    onBack={noop}
    onContinue={noop}
    onTokenPress={noop}
    {...overrides}
  />
);

type Case = { element: () => React.ReactElement };

const cases: { screen: string; states: Record<string, Case> }[] = [
  {
    screen: 'userDetails',
    states: {
      // The design's three: placeholders, a filled form, and the row a token already supplied.
      empty: { element: () => userDetails() },
      complete: {
        element: () =>
          userDetails({
            state: {
              productLabel: 'Biometric KYC',
              details: FILLED_DETAILS,
              rememberDetails: true,
            },
          }),
      },
      tokenSuppliedNames: {
        element: () =>
          userDetails({
            state: {
              productLabel: 'Biometric KYC',
              details: EMPTY_DETAILS,
              rememberDetails: true,
              requirement: smileIDSampleRequirementFrom({ givenNames: true, lastName: true }),
            },
          }),
      },
    },
  },
  {
    screen: 'kycIdForm',
    states: {
      // ID type is disabled without a country, which is the state the disabled trigger exists for.
      empty: { element: () => kycForm() },
      selected: {
        element: () =>
          kycForm({
            state: {
              productLabel: 'Biometric KYC',
              details: { country: KENYA, idType: NATIONAL_ID, idNumber: 'AO12345678' },
            },
          }),
      },
    },
  },
  {
    screen: 'countryPickerSheet',
    states: {
      default: {
        element: () => (
          <CountryPickerSheet
            selected={null}
            query=""
            onQueryChange={noop}
            onSelect={noop}
            onDismiss={noop}
          />
        ),
      },
      noMatch: {
        element: () => (
          <CountryPickerSheet
            selected={NIGERIA}
            query="zz"
            onQueryChange={noop}
            onSelect={noop}
            onDismiss={noop}
          />
        ),
      },
    },
  },
  {
    screen: 'idTypePickerSheet',
    states: {
      default: {
        element: () => (
          <IdTypePickerSheet
            country={KENYA}
            selected={null}
            query=""
            onQueryChange={noop}
            onSelect={noop}
            onDismiss={noop}
          />
        ),
      },
      // Without a country the list is empty for a different reason, and says so.
      noCountry: {
        element: () => (
          <IdTypePickerSheet
            country={null}
            selected={null}
            query=""
            onQueryChange={noop}
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

describe('forms coverage', () => {
  it('records both schemes for every state', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(18);
  });
});

describe('the ID-type list', () => {
  it('is empty without a country, which is what disables the trigger that opens it', () => {
    expect(smileIDSampleIdTypesFor(null)).toEqual([]);
  });

  it('is filtered by country rather than fixed, or the picker would offer an unusable type', () => {
    const uganda = smileIDSampleIdTypesFor(UGANDA).map((type) => type.id);
    const nigeria = smileIDSampleIdTypesFor(NIGERIA).map((type) => type.id);
    expect(uganda).toEqual(['NATIONAL_ID', 'PASSPORT']);
    expect(nigeria).toEqual(['NATIONAL_ID', 'PASSPORT', 'DRIVERS_LICENSE', 'VOTER_ID']);
  });

  it('matches case-insensitively, so a lowercase query still finds a capitalised label', () => {
    expect(smileIDSampleOptionMatches('South Africa', 'south')).toBe(true);
    expect(smileIDSampleOptionMatches('South Africa', '  SOUTH  ')).toBe(true);
    expect(smileIDSampleOptionMatches('South Africa', 'zz')).toBe(false);
  });
});

describe('choosing a country', () => {
  beforeEach(() => {
    useSmileIDSampleFormsStore.getState().clear();
  });

  it('clears the ID type, because the types it offered may not apply to the new country', () => {
    const store = useSmileIDSampleFormsStore.getState();
    store.setCountry(NIGERIA);
    useSmileIDSampleFormsStore.getState().setIdType(NATIONAL_ID);
    expect(useSmileIDSampleFormsStore.getState().idDetails.idType).toEqual(NATIONAL_ID);

    useSmileIDSampleFormsStore.getState().setCountry(KENYA);
    expect(useSmileIDSampleFormsStore.getState().idDetails.idType).toBeNull();
    expect(useSmileIDSampleFormsStore.getState().idDetails.country).toEqual(KENYA);
  });

  it('keeps the ID number, which the country does not invalidate', () => {
    useSmileIDSampleFormsStore.getState().setIdNumber('A01234567');
    useSmileIDSampleFormsStore.getState().setCountry(KENYA);
    expect(useSmileIDSampleFormsStore.getState().idDetails.idNumber).toBe('A01234567');
  });
});

describe('the ID-details form is complete', () => {
  it('only once all three are set, which is what the CTA waits for', () => {
    expect(smileIDSampleIdDetailsComplete(smileIDSampleIdDetailsDefaults)).toBe(false);
    expect(
      smileIDSampleIdDetailsComplete({ country: NIGERIA, idType: NATIONAL_ID, idNumber: '' }),
    ).toBe(false);
    expect(
      smileIDSampleIdDetailsComplete({ country: NIGERIA, idType: null, idNumber: 'A1' }),
    ).toBe(false);
    expect(
      smileIDSampleIdDetailsComplete({ country: NIGERIA, idType: NATIONAL_ID, idNumber: 'A1' }),
    ).toBe(true);
  });

  it('treats blank space as unset, or a space would enable the CTA', () => {
    expect(
      smileIDSampleIdDetailsComplete({ country: NIGERIA, idType: NATIONAL_ID, idNumber: '   ' }),
    ).toBe(false);
  });
});

describe('the token requirement', () => {
  it('asks for everything when no token binds anything', () => {
    expect(smileIDSampleRequirementFrom(null)).toEqual(smileIDSampleRequirementDefaults);
    expect(smileIDSampleRequirementFrom(undefined)).toEqual(smileIDSampleRequirementDefaults);
    expect(smileIDSampleRequirementFrom({})).toEqual(smileIDSampleRequirementDefaults);
  });

  it('lifts contact when either half is bound, because the SDK rule is one of the two', () => {
    expect(smileIDSampleRequirementFrom({ email: true }).contact).toBe(false);
    expect(smileIDSampleRequirementFrom({ phoneNumber: true }).contact).toBe(false);
  });

  it('never marks an individual contact row supplied, since the other is still askable', () => {
    const requirement = smileIDSampleRequirementFrom({ email: true });
    expect(smileIDSampleRequirementSupplies(requirement, UseSmileIDSampleUserField.Email)).toBe(false);
    expect(smileIDSampleRequirementSupplies(requirement, UseSmileIDSampleUserField.Phone)).toBe(false);
  });

  it('marks a bound name supplied, which is why that row renders as provided', () => {
    const requirement = smileIDSampleRequirementFrom({ givenNames: true });
    expect(smileIDSampleRequirementSupplies(requirement, UseSmileIDSampleUserField.FirstName)).toBe(true);
    expect(smileIDSampleRequirementSupplies(requirement, UseSmileIDSampleUserField.LastName)).toBe(false);
  });

  it('is satisfied only when a token has bound every part of the rule', () => {
    const all = smileIDSampleRequirementFrom({ givenNames: true, lastName: true, email: true });
    expect(smileIDSampleRequirementSatisfied(all)).toBe(true);
    expect(smileIDSampleRequirementSatisfied(smileIDSampleRequirementDefaults)).toBe(false);
  });

  it('drops "(optional)" from a contact label only once neither half is required', () => {
    const email = smileIDSampleUserFields.find((f) => f.id === UseSmileIDSampleUserField.Email)!;
    expect(smileIDSampleRequirementLabel(smileIDSampleRequirementDefaults, email)).toBe('Email');
    expect(smileIDSampleRequirementLabel(smileIDSampleRequirementFrom({ email: true }), email)).toBe(
      'Email (optional)',
    );
  });

  it('names what is outstanding rather than repeating one fixed sentence', () => {
    expect(smileIDSampleRequirementPrompt(smileIDSampleRequirementDefaults)).toBe(
      'Required: first name, last name, an email or phone number.',
    );
    expect(
      smileIDSampleRequirementPrompt(
        smileIDSampleRequirementFrom({ givenNames: true, lastName: true }),
      ),
    ).toBe('An email or phone number is required.');
    expect(
      smileIDSampleRequirementPrompt(
        smileIDSampleRequirementFrom({ givenNames: true, lastName: true, email: true }),
      ),
    ).toBe('Tap any field to edit.');
  });
});

describe('the consent form is satisfied', () => {
  it('by either contact route, never demanding both', () => {
    const withEmail = { ...EMPTY_DETAILS, firstName: 'A', lastName: 'B', email: 'a@b.example' };
    const withPhone = { ...EMPTY_DETAILS, firstName: 'A', lastName: 'B', phone: '+254700000000' };
    expect(smileIDSampleDetailsSatisfy(withEmail, smileIDSampleRequirementDefaults)).toBe(true);
    expect(smileIDSampleDetailsSatisfy(withPhone, smileIDSampleRequirementDefaults)).toBe(true);
  });

  it('ignores a row the token supplied, or a bound name would block the CTA forever', () => {
    const requirement = smileIDSampleRequirementFrom({ givenNames: true, lastName: true });
    expect(smileIDSampleDetailsSatisfy(EMPTY_DETAILS, requirement)).toBe(false);
    expect(
      smileIDSampleDetailsSatisfy({ ...EMPTY_DETAILS, email: 'a@b.example' }, requirement),
    ).toBe(true);
  });
});

describe('the consent form', () => {
  it('hides the remember switch until the details are worth remembering', async () => {
    const empty = await renderInTheme(userDetails(), false);
    expect(empty.queryByTestId(UseSmileIDSampleTestIds.REMEMBER_DETAILS_SWITCH)).toBeNull();

    const complete = await renderInTheme(
      userDetails({
        state: { productLabel: 'Biometric KYC', details: FILLED_DETAILS, rememberDetails: false },
      }),
      false,
    );
    expect(
      complete.queryByTestId(UseSmileIDSampleTestIds.REMEMBER_DETAILS_SWITCH),
    ).not.toBeNull();
  });

  it('reports the field rather than four callbacks, so the host writes one store', async () => {
    const changed: [string, string][] = [];
    const rendered = await renderInTheme(
      userDetails({ onFieldChange: (field, value) => changed.push([field, value]) }),
      false,
    );
    await fireEvent.changeText(
      rendered.getByTestId('sample_user_details_field_lastName'),
      'Asante',
    );
    expect(changed).toEqual([['lastName', 'Asante']]);
  });

  it('leaves a token-supplied row uneditable rather than merely empty', async () => {
    const rendered = await renderInTheme(
      userDetails({
        state: {
          productLabel: 'Biometric KYC',
          details: EMPTY_DETAILS,
          rememberDetails: false,
          requirement: smileIDSampleRequirementFrom({ givenNames: true }),
        },
      }),
      false,
    );
    const row = rendered.getByTestId('sample_user_details_field_firstName');
    expect(row.props.editable).toBe(false);
  });
});

describe('the pickers', () => {
  it('say why the list is empty, telling a missing country from a missing match', async () => {
    const noCountry = await renderInTheme(
      <IdTypePickerSheet
        country={null}
        selected={null}
        query=""
        onQueryChange={noop}
        onSelect={noop}
        onDismiss={noop}
      />,
      false,
    );
    expect(noCountry.queryByText('No ID type for this country')).not.toBeNull();

    const noMatch = await renderInTheme(
      <IdTypePickerSheet
        country={NIGERIA}
        selected={null}
        query="zz"
        onQueryChange={noop}
        onSelect={noop}
        onDismiss={noop}
      />,
      false,
    );
    expect(noMatch.queryByText('No ID type matches “zz”')).not.toBeNull();
  });

  it('give every option an id built from its code, which is what a flow taps', async () => {
    const rendered = await renderInTheme(
      <CountryPickerSheet
        selected={null}
        query=""
        onQueryChange={noop}
        onSelect={noop}
        onDismiss={noop}
      />,
      false,
    );
    for (const country of smileIDSampleCountries) {
      expect(rendered.queryByTestId(`sample_country_option_${country.code}`)).not.toBeNull();
    }
  });
});

describe('the search field on a picker', () => {
  it('records its focused state, which an unawaited event would silently miss', async () => {
    const unfocused = await styleTree(
      <CountryPickerSheet
        selected={null}
        query="Ken"
        onQueryChange={noop}
        onSelect={noop}
        onDismiss={noop}
      />,
      false,
    );
    const focused = await styleTree(
      <CountryPickerSheet
        selected={null}
        query="Ken"
        onQueryChange={noop}
        onSelect={noop}
        onDismiss={noop}
      />,
      false,
      focusField(UseSmileIDSampleTestIds.COUNTRY_SEARCH),
    );
    expect(JSON.stringify(focused)).not.toEqual(JSON.stringify(unfocused));
  });
});
