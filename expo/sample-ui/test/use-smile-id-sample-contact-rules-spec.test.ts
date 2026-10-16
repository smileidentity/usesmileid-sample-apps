import { smileIDSampleNewProfileComplete } from '../src/screens/new-profile-sheet';
import { smileIDSampleContactSubmitted } from '../src/state/use-smile-id-sample-contact-rules';
import {
  smileIDSampleDetailsSatisfy,
  smileIDSampleRequirementDefaults,
} from '../src/state/use-smile-id-sample-user-details-requirement';
import { spec } from './spec-file';

type Case = { field: 'email' | 'phone'; value: string; submits: string };
const file = spec<{ cases: Case[] }>('contact-rules.json');

/// spec/contact-rules.json: what each email and phone number submits, and that no form checks either.
describe('the contact rules', () => {
  it.each(file.cases.map((c) => [c.field, c.value, c] as const))('%s "%s" submits as the spec says', (_field, _value, c) => {
    expect(smileIDSampleContactSubmitted(c.field, c.value)).toBe(c.submits);
  });

  it.each(file.cases.filter((c) => c.submits.length > 0).map((c) => [c.field, c.value, c] as const))(
    '%s "%s" never holds a form back',
    (_field, _value, c) => {
      const named = { firstName: 'Ada', lastName: 'Okafor', email: '', phone: '', [c.field]: c.value };
      expect(smileIDSampleDetailsSatisfy(named, smileIDSampleRequirementDefaults)).toBe(true);
      expect(smileIDSampleNewProfileComplete({ name: 'Uptech', ...named })).toBe(true);
    },
  );
});
