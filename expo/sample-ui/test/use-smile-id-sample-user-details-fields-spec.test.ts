import { smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleUserField } from '../src/model/use-smile-id-sample-user-fields';
import {
  smileIDSampleDecodeFieldsToCollect,
  smileIDSampleFieldsToCollectSection,
} from '../src/state/use-smile-id-sample-catalogue';
import {
  smileIDSampleDetailsSatisfy,
  smileIDSampleDetailsWithoutHiddenNames,
  smileIDSampleFieldsToCollectKey,
  smileIDSampleRequirementFor,
  smileIDSampleRequirementShows,
  smileIDSampleRequirementSupplies,
  type UseSmileIDSampleUserDetailsRequirement,
} from '../src/state/use-smile-id-sample-user-details-requirement';
import { spec } from './spec-file';

type Outcome = 'ask' | 'hidden' | 'provided';
type Case = {
  name: string;
  product: string;
  fieldsToCollect: Record<string, unknown> | null;
  bindings: { givenNames?: boolean; lastName?: boolean; email?: boolean; phoneNumber?: boolean };
  expect: { firstName: Outcome; lastName: Outcome; contact: 'ask' | 'provided' };
};
const file = spec<{ productKeys: Record<string, string | null>; cases: Case[] }>('user-details-fields.json');

const outcome = (requirement: UseSmileIDSampleUserDetailsRequirement, field: UseSmileIDSampleUserField): Outcome => {
  if (!smileIDSampleRequirementShows(requirement, field)) return 'hidden';
  return smileIDSampleRequirementSupplies(requirement, field) ? 'provided' : 'ask';
};

const details = (overrides: Partial<{ firstName: string; lastName: string; email: string }>) => ({
  firstName: '',
  lastName: '',
  email: '',
  phone: '',
  ...overrides,
});

/// spec/user-details-fields.json: which user-details rows the form shows for a product.
describe('the user-details fields', () => {
  it('reads every product at the spec key', () => {
    expect(Object.keys(file.productKeys).sort()).toEqual(smileIDSampleProducts.map((product) => product.id).sort());
    for (const product of smileIDSampleProducts) {
      expect(smileIDSampleFieldsToCollectKey(product)).toBe(file.productKeys[product.id]);
    }
  });

  it.each(file.cases.map((c) => [c.name, c] as const))('%s', (_name, c) => {
    const product = smileIDSampleProducts.find((it) => it.id === c.product) ?? null;
    const fields = c.fieldsToCollect === null ? null : smileIDSampleFieldsToCollectSection(c.fieldsToCollect);
    const bindings = {
      givenNames: c.bindings.givenNames === true,
      lastName: c.bindings.lastName === true,
      email: c.bindings.email === true,
      phoneNumber: c.bindings.phoneNumber === true,
    };
    const requirement = smileIDSampleRequirementFor(bindings, product, fields);
    expect(outcome(requirement, UseSmileIDSampleUserField.FirstName)).toBe(c.expect.firstName);
    expect(outcome(requirement, UseSmileIDSampleUserField.LastName)).toBe(c.expect.lastName);
    expect(requirement.contact ? 'ask' : 'provided').toBe(c.expect.contact);
  });

  it('keeps the token rule for a config that does not parse', () => {
    expect(smileIDSampleDecodeFieldsToCollect('not json')).toBeNull();
    expect(smileIDSampleDecodeFieldsToCollect('{"products": {}}')).toEqual({});
  });

  it('never holds the form back on a hidden name, and submits none', () => {
    const requirement: UseSmileIDSampleUserDetailsRequirement = {
      firstName: false,
      lastName: false,
      contact: true,
      hidden: [UseSmileIDSampleUserField.FirstName, UseSmileIDSampleUserField.LastName],
    };
    const typed = details({ firstName: 'Ada', lastName: 'Okafor', email: 'ada@example.com' });
    expect(smileIDSampleDetailsSatisfy(details({ email: 'ada@example.com' }), requirement)).toBe(true);
    expect(smileIDSampleRequirementSupplies(requirement, UseSmileIDSampleUserField.FirstName)).toBe(false);
    expect(smileIDSampleDetailsWithoutHiddenNames(typed, requirement)).toEqual(details({ email: 'ada@example.com' }));
    expect(smileIDSampleDetailsWithoutHiddenNames(typed, { firstName: true, lastName: true, contact: true })).toEqual(typed);
  });
});
