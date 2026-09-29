import { act, fireEvent } from '@testing-library/react-native';
import { AccessibilityInfo } from 'react-native';

import { UseSmileIDSampleCaptureMode } from '../src/model/use-smile-id-sample-capture-mode';
import type { UseSmileIDSampleCatalogue } from '../src/state/use-smile-id-sample-catalogue';
import {
  smileIDSampleGenericDocumentDefaults,
  smileIDSampleIdDetailsComplete,
  smileIDSampleIdDetailsDefaults,
  smileIDSampleOptionMatches,
  smileIDSampleResolvedCaptureAs,
  type UseSmileIDSampleCountry,
  type UseSmileIDSampleDocument,
  type UseSmileIDSampleIdDetails,
  type UseSmileIDSampleKycIdType,
} from '../src/state/use-smile-id-sample-id-details';
import { UseSmileIDSampleCaptureAs } from '../src/model/use-smile-id-sample-capture-as';
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
import { UseSmileIDSampleUserField, smileIDSampleUserFields } from '../src/model/use-smile-id-sample-user-fields';
import { UseSmileIDSampleCataloguePicker } from '../src/components/use-smile-id-sample-catalogue-picker';
import { CaptureAsSheet } from '../src/screens/capture-as-sheet';
import { CaptureModeSheet } from '../src/screens/capture-mode-sheet';
import { CountryPickerSheet } from '../src/screens/country-picker-sheet';
import { GenericDocumentSheet } from '../src/screens/generic-document-sheet';
import { DocumentPickerSheet } from '../src/screens/document-picker-sheet';
import { IdTypePickerSheet } from '../src/screens/id-type-picker-sheet';
import { KycIdFormScreen } from '../src/screens/kyc-id-form-screen';
import { UserDetailsScreen } from '../src/screens/user-details-screen';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { focusField, renderInTheme, schemes, styleTree } from './render-in-theme';
import { expectGoldens } from './paint/pixel-golden';
import { KENYA, SOUTH_AFRICA, fixtureCountries, fixtureDocuments, fixtureIdTypes } from './catalogue-fixtures';

const noop = () => {};

const NATIONAL_ID = fixtureIdTypes('KE').find((type) => type.type === 'NATIONAL_ID')!;
const GREEN_BOOK = fixtureDocuments('ZA').find((document) => document.subType === 'green_book')!;
const kenyanRow = (code: string) => fixtureDocuments('KE').find((document) => document.code === code)!;
const RWANDA: UseSmileIDSampleCountry = { code: 'RW', name: 'Rwanda' };
const ARABIC_DOCUMENTS: UseSmileIDSampleDocument[] = [
  { code: 'ALIEN_CARD', subType: null, name: 'بطاقة الأجانب', hasBack: false, format: 1 },
  { code: 'IDENTITY_CARD', subType: null, name: 'بطاقة الهوية', hasBack: true, format: 1 },
  { code: 'PASSPORT', subType: null, name: 'جواز السفر', hasBack: false, format: 3 },
];

/// A country chosen and nothing else, which is the only state that unlocks the second trigger.
const COUNTRY_ONLY: UseSmileIDSampleIdDetails = {
  ...smileIDSampleIdDetailsDefaults,
  country: KENYA,
};
const SELECTED: UseSmileIDSampleIdDetails = {
  ...COUNTRY_ONLY,
  idType: NATIONAL_ID,
  idNumber: '12345678',
};

const loading = { kind: 'loading' } as const;
const failed = { kind: 'failed', reason: 'offline' } as const;
const empty = { kind: 'empty' } as const;
const ready = <T,>(items: readonly T[]): UseSmileIDSampleCatalogue<T> => ({
  kind: 'ready',
  items,
});

/// Past the 300 ms before skeleton rows appear.
const pastSkeletonDelay = async () => {
  await act(() => new Promise((resolve) => setTimeout(resolve, 350)));
};

// Reduced motion stops the pulse at its first frame, so a skeleton golden is stable.
beforeAll(() => {
  jest.spyOn(AccessibilityInfo, 'isReduceMotionEnabled').mockResolvedValue(true);
});

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
    state={{
      productLabel: 'Biometric KYC',
      details: EMPTY_DETAILS,
      profile: null,
      saveToProfile: true,
    }}
    onFieldChange={noop}
    onSaveToProfileChange={noop}
    onProfilePress={noop}
    onBack={noop}
    onContinue={noop}
    {...overrides}
  />
);

const kycForm = (
  overrides: Partial<Parameters<typeof KycIdFormScreen>[0]> = {},
): React.ReactElement => (
  <KycIdFormScreen
    state={{
      productLabel: 'Biometric KYC',
      family: 'kyc',
      details: smileIDSampleIdDetailsDefaults,
      countryListLoading: false,
      captureBothSides: true,
    }}
    onCountryPress={noop}
    onIdTypePress={noop}
    onDocumentPress={noop}
    onCaptureAsPress={noop}
    onIdNumberChange={noop}
    onBack={noop}
    onContinue={noop}
    onTokenPress={noop}
    {...overrides}
  />
);

type Case = {
  element: () => React.ReactElement;
  interact?: () => Promise<void>;
};

const country = (catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleCountry>, query = '') => (
  <CountryPickerSheet
    catalogue={catalogue}
    selected={null}
    query={query}
    onQueryChange={noop}
    onSelect={noop}
    onRetry={noop}
    onDismiss={noop}
  />
);

const idType = (
  catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType>,
  forCountry: UseSmileIDSampleCountry | null = KENYA,
  query = '',
) => (
  <IdTypePickerSheet
    country={forCountry}
    catalogue={catalogue}
    selected={null}
    query={query}
    onQueryChange={noop}
    onSelect={noop}
    onRetry={noop}
    onDismiss={noop}
  />
);

const document = (catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleDocument>) => (
  <DocumentPickerSheet
    country={SOUTH_AFRICA}
    catalogue={catalogue}
    selected={null}
    query=""
    onQueryChange={noop}
    onSelect={noop}
    onRetry={noop}
    onDismiss={noop}
  />
);

const kycState = (details: UseSmileIDSampleIdDetails, countryListLoading = false) => ({
  state: {
    productLabel: 'Biometric KYC',
    family: 'kyc' as const,
    details,
    countryListLoading,
    captureBothSides: true,
  },
});

/// A Kenyan fixture row on Document Verification, with "Capture as" untouched unless the details say otherwise.
const documentForm = (details: Partial<UseSmileIDSampleIdDetails>) =>
  kycForm({
    state: {
      productLabel: 'Document Verification',
      family: 'document',
      details: { ...smileIDSampleIdDetailsDefaults, country: KENYA, ...details },
      countryListLoading: false,
      captureBothSides: true,
    },
  });

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
              profile: null, saveToProfile: true,
            },
          }),
      },
      tokenSuppliedNames: {
        element: () =>
          userDetails({
            state: {
              productLabel: 'Biometric KYC',
              details: EMPTY_DETAILS,
              profile: null,
              saveToProfile: true,
              requirement: smileIDSampleRequirementFrom({
                givenNames: true,
                lastName: true,
              }),
            },
          }),
      },
    },
  },
  {
    screen: 'kycIdForm',
    states: {
      empty: { element: () => kycForm() },
      selected: { element: () => kycForm(kycState(SELECTED)) },
      // Letters where Kenya's National ID takes only digits, so the field explains the format.
      idNumberInvalid: {
        element: () => kycForm(kycState({ ...SELECTED, idNumber: 'AO12345678' })),
      },
      // The country's list is still arriving: the trigger stays enabled and says so.
      loading: { element: () => kycForm(kycState(COUNTRY_ONLY, true)) },
      // The list failed: the trigger goes back to its prompt, so the form never looks stuck.
      catalogueError: { element: () => kycForm(kycState(COUNTRY_ONLY)) },
      documentSelected: {
        element: () =>
          kycForm({
            state: {
              productLabel: 'Document Verification',
              family: 'document',
              details: {
                ...smileIDSampleIdDetailsDefaults,
                country: SOUTH_AFRICA,
                document: GREEN_BOOK,
              },
              countryListLoading: false,
              captureBothSides: true,
            },
          }),
      },
      documentPassportMatched: { element: () => documentForm({ document: kenyanRow('PASSPORT') }) },
      documentTwoSidedMatched: { element: () => documentForm({ document: kenyanRow('IDENTITY_CARD') }) },
      documentOneSidedMatched: { element: () => documentForm({ document: kenyanRow('ALIEN_CARD') }) },
      documentPresetChosen: {
        element: () =>
          documentForm({ document: kenyanRow('IDENTITY_CARD'), captureAsOverride: UseSmileIDSampleCaptureAs.Passport }),
      },
      documentGenericChosen: {
        element: () =>
          documentForm({
            document: kenyanRow('PASSPORT'),
            captureAsOverride: UseSmileIDSampleCaptureAs.GenericDocument,
            genericDocument: { displayName: 'Booklet', hasBackSide: true, orientation: 'portrait', aspectRatio: 'booklet' },
          }),
      },
    },
  },
  {
    screen: 'countryPickerSheet',
    states: {
      default: { element: () => country(ready(fixtureCountries('kyc'))) },
      noMatch: { element: () => country(ready(fixtureCountries('kyc')), 'zz') },
      loading: { element: () => country(loading), interact: pastSkeletonDelay },
      error: { element: () => country(failed) },
      empty: { element: () => country(empty) },
    },
  },
  {
    screen: 'idTypePickerSheet',
    states: {
      default: { element: () => idType(ready(fixtureIdTypes('KE'))) },
      loading: { element: () => idType(loading), interact: pastSkeletonDelay },
      error: { element: () => idType(failed) },
      empty: { element: () => idType(empty, RWANDA) },
    },
  },
  {
    screen: 'documentPickerSheet',
    states: {
      default: { element: () => document(ready(fixtureDocuments('ZA'))) },
      // Only names are translated under ar-EG, and the app does not flip its own layout.
      arabicNames: { element: () => document(ready(ARABIC_DOCUMENTS)) },
      loading: {
        element: () => document(loading),
        interact: pastSkeletonDelay,
      },
      error: { element: () => document(failed) },
      empty: { element: () => document(empty) },
      // South Africa on Enhanced Document Verification, which leaves out the Green Book the SDK refuses there.
      enhanced: { element: () => document(ready(fixtureDocuments('ZA', 'enhancedDocumentVerification'))) },
    },
  },
  {
    screen: 'captureAsSheet',
    states: {
      default: {
        element: () => (
          <CaptureAsSheet
            selected={null}
            matched={smileIDSampleResolvedCaptureAs(kenyanRow('PASSPORT'), null, smileIDSampleGenericDocumentDefaults)}
            onSelect={noop}
            onDismiss={noop}
          />
        ),
      },
    },
  },
  {
    screen: 'genericDocumentSheet',
    states: {
      default: {
        element: () => (
          <GenericDocumentSheet initial={smileIDSampleGenericDocumentDefaults} onDone={noop} onDismiss={noop} />
        ),
      },
    },
  },
  {
    screen: 'captureModeSheet',
    states: {
      default: {
        element: () => (
          <CaptureModeSheet selected={UseSmileIDSampleCaptureMode.AutoWithFallback} onSelect={noop} onDismiss={noop} />
        ),
      },
    },
  },
];

describe.each(cases)('$screen', ({ states }) => {
  describe.each(schemes)('$name', ({ dark }) => {
    it.each(Object.keys(states))('%s', async (state) => {
      const entry = states[state]!;
      await expectGoldens(entry.element(), dark, entry.interact ? { interact: entry.interact } : {});
    });
  });
});

describe('forms coverage', () => {
  it('records both schemes for every state', () => {
    const total = cases.reduce((sum, entry) => sum + Object.keys(entry.states).length, 0);
    expect(total * schemes.length).toBe(64);
  });
});

describe('the picker search', () => {
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

  it("clears the ID type and document, because the old country's may not apply", () => {
    useSmileIDSampleFormsStore.getState().setCountry(SOUTH_AFRICA);
    useSmileIDSampleFormsStore.getState().setIdType(NATIONAL_ID);
    useSmileIDSampleFormsStore.getState().setDocument(GREEN_BOOK);

    useSmileIDSampleFormsStore.getState().setCountry(KENYA);
    expect(useSmileIDSampleFormsStore.getState().idDetails.idType).toBeNull();
    expect(useSmileIDSampleFormsStore.getState().idDetails.document).toBeNull();
    expect(useSmileIDSampleFormsStore.getState().idDetails.country).toEqual(KENYA);
  });

  it('keeps the ID number, which the country does not invalidate', () => {
    useSmileIDSampleFormsStore.getState().setIdNumber('A01234567');
    useSmileIDSampleFormsStore.getState().setCountry(KENYA);
    expect(useSmileIDSampleFormsStore.getState().idDetails.idNumber).toBe('A01234567');
  });

  it('keeps what the generic-document sheet built as Generic document', () => {
    useSmileIDSampleFormsStore.getState().setGenericDocument({
      ...smileIDSampleGenericDocumentDefaults,
      displayName: 'Booklet',
    });
    expect(useSmileIDSampleFormsStore.getState().idDetails.captureAsOverride).toBe(UseSmileIDSampleCaptureAs.GenericDocument);
    expect(useSmileIDSampleFormsStore.getState().idDetails.genericDocument.displayName).toBe('Booklet');
  });
});

describe('the ID-details form is complete', () => {
  it('for KYC, once the number fits its type', () => {
    expect(smileIDSampleIdDetailsComplete(smileIDSampleIdDetailsDefaults, 'kyc')).toBe(false);
    expect(smileIDSampleIdDetailsComplete({ ...SELECTED, idNumber: '' }, 'kyc')).toBe(false);
    expect(smileIDSampleIdDetailsComplete({ ...SELECTED, idNumber: 'AO12345678' }, 'kyc')).toBe(false);
    expect(smileIDSampleIdDetailsComplete({ ...SELECTED, idNumber: '   ' }, 'kyc')).toBe(false);
    expect(smileIDSampleIdDetailsComplete(SELECTED, 'kyc')).toBe(true);
  });

  it('for a document product, with a country and a document and no number', () => {
    expect(smileIDSampleIdDetailsComplete(COUNTRY_ONLY, 'document')).toBe(false);
    expect(smileIDSampleIdDetailsComplete({ ...COUNTRY_ONLY, document: GREEN_BOOK }, 'document')).toBe(true);
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
    const all = smileIDSampleRequirementFrom({
      givenNames: true,
      lastName: true,
      email: true,
    });
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
        smileIDSampleRequirementFrom({
          givenNames: true,
          lastName: true,
          email: true,
        }),
      ),
    ).toBe('Tap any field to edit.');
  });
});

describe('the consent form is satisfied', () => {
  it('by either contact route, never demanding both', () => {
    const withEmail = {
      ...EMPTY_DETAILS,
      firstName: 'A',
      lastName: 'B',
      email: 'a@b.example',
    };
    const withPhone = {
      ...EMPTY_DETAILS,
      firstName: 'A',
      lastName: 'B',
      phone: '+254700000000',
    };
    expect(smileIDSampleDetailsSatisfy(withEmail, smileIDSampleRequirementDefaults)).toBe(true);
    expect(smileIDSampleDetailsSatisfy(withPhone, smileIDSampleRequirementDefaults)).toBe(true);
  });

  it('ignores a row the token supplied, or a bound name would block the CTA forever', () => {
    const requirement = smileIDSampleRequirementFrom({
      givenNames: true,
      lastName: true,
    });
    expect(smileIDSampleDetailsSatisfy(EMPTY_DETAILS, requirement)).toBe(false);
    expect(
      smileIDSampleDetailsSatisfy({ ...EMPTY_DETAILS, email: 'a@b.example' }, requirement),
    ).toBe(true);
  });
});

describe('the consent form', () => {
  it('hides the save switch until the details are worth keeping', async () => {
    const empty = await renderInTheme(userDetails(), false);
    expect(empty.queryByTestId(UseSmileIDSampleTestIds.REMEMBER_DETAILS_SWITCH)).toBeNull();

    const complete = await renderInTheme(
      userDetails({
        state: {
          productLabel: 'Biometric KYC',
          details: FILLED_DETAILS,
          profile: null,
          saveToProfile: false,
        },
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
      userDetails({
        onFieldChange: (field, value) => changed.push([field, value]),
      }),
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
          profile: null, saveToProfile: false,
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
  it('tell a list with nothing in it from a search that matched nothing', async () => {
    const nothing = await renderInTheme(idType(empty, RWANDA), false);
    expect(nothing.queryByText('No ID types for Rwanda')).not.toBeNull();

    const noMatch = await renderInTheme(idType(ready(fixtureIdTypes('KE')), KENYA, 'zz'), false);
    expect(noMatch.queryByText('No ID type matches “zz”')).not.toBeNull();
  });

  it('offer Retry only on a failure', async () => {
    const onRetry = jest.fn();
    // The picker body alone: under jest the platform sheet's host takes no touches.
    const rendered = await renderInTheme(
      <UseSmileIDSampleCataloguePicker<UseSmileIDSampleCountry>
        catalogue={failed}
        what="countries"
        query=""
        onQueryChange={noop}
        searchPlaceholder="Search country"
        searchTestID={UseSmileIDSampleTestIds.COUNTRY_SEARCH}
        label={(it) => it.name}
        emptyTestID={UseSmileIDSampleTestIds.COUNTRY_EMPTY}
        emptyLabel={() => ''}
        nothingToList={['', '']}
        onRetry={onRetry}
        row={() => null}
      />,
      false,
    );
    await fireEvent.press(rendered.getByTestId(UseSmileIDSampleTestIds.CATALOGUE_RETRY));
    expect(onRetry).toHaveBeenCalledTimes(1);

    const nothing = await renderInTheme(country(empty), false);
    expect(nothing.queryByTestId(UseSmileIDSampleTestIds.CATALOGUE_RETRY)).toBeNull();
  });

  it('draw nothing for the first 300 ms of a load, then skeleton rows', async () => {
    const rendered = await renderInTheme(country(loading), false);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.CATALOGUE_LOADING)).toBeNull();
    await pastSkeletonDelay();
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.CATALOGUE_LOADING)).not.toBeNull();
  });

  it('give every option an id built from its code, which is what a flow taps', async () => {
    const rendered = await renderInTheme(country(ready(fixtureCountries('kyc'))), false);
    for (const each of fixtureCountries('kyc')) {
      expect(rendered.queryByTestId(`sample_country_option_${each.code}`)).not.toBeNull();
    }
    const documents = await renderInTheme(document(ready(fixtureDocuments('ZA'))), false);
    expect(documents.queryByTestId('sample_document_option_IDENTITY_CARD_green_book')).not.toBeNull();
    expect(documents.queryByTestId('sample_document_option_')).toBeNull();
  });
});

describe('the ID number field', () => {
  it('shows the example and, for a number outside the format, the error line', async () => {
    const rendered = await renderInTheme(kycForm(kycState({ ...SELECTED, idNumber: 'AO12345678' })), false);
    expect(rendered.queryByTestId(UseSmileIDSampleTestIds.ID_NUMBER_ERROR)).not.toBeNull();
    expect(rendered.queryByText("Doesn't match the National ID format, e.g. 000000000")).not.toBeNull();
  });
});

describe('the search field on a picker', () => {
  it('records its focused state, which an unawaited event would silently miss', async () => {
    const unfocused = await styleTree(country(ready(fixtureCountries('kyc')), 'Ken'), false);
    const focused = await styleTree(
      country(ready(fixtureCountries('kyc')), 'Ken'),
      false,
      focusField(UseSmileIDSampleTestIds.COUNTRY_SEARCH),
    );
    expect(JSON.stringify(focused)).not.toEqual(JSON.stringify(unfocused));
  });
});
