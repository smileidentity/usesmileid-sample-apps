import { UseSmileIDSampleUserField } from '../src/model/use-smile-id-sample-user-fields';
import {
  smileIDSampleContactProblem,
  smileIDSampleContactProblemText,
  smileIDSampleContactSubmitted,
} from '../src/state/use-smile-id-sample-contact-rules';
import {
  smileIDSampleDetailsSatisfy,
  smileIDSampleRequirementDefaults,
} from '../src/state/use-smile-id-sample-user-details-requirement';
import { spec } from './spec-file';
import { UseSmileIDSampleStrings } from '../src/use-smile-id-sample-strings';

const strings = UseSmileIDSampleStrings.forLanguage('en');

type Case = { field: 'email' | 'phone'; value: string; valid: boolean; submits?: string };
const file = spec<{ email: { error: string }; phone: { error: string }; cases: Case[] }>('contact-rules.json');

/// spec/contact-rules.json: which emails and phone numbers pass, what each submits, and the error it shows.
describe('the contact rules', () => {
  it.each(file.cases.map((c) => [c.field, c.value, c] as const))('%s "%s" matches the spec', (_field, _value, c) => {
    expect(smileIDSampleContactProblem(c.field, c.value) === null).toBe(c.valid);
    if (c.valid) expect(smileIDSampleContactSubmitted(c.field, c.value)).toBe(c.submits);
  });

  it('shows the spec sentences', () => {
    expect(smileIDSampleContactProblemText(smileIDSampleContactProblem(UseSmileIDSampleUserField.Email, 'ada')!, strings)).toBe(
      file.email.error,
    );
    expect(smileIDSampleContactProblemText(smileIDSampleContactProblem(UseSmileIDSampleUserField.Phone, '0700')!, strings)).toBe(
      file.phone.error,
    );
  });

  it('keeps the form from continuing on a bad contact but not on a blank one', () => {
    const named = { firstName: 'Ada', lastName: 'Okafor', email: 'ada@example.com', phone: '' };
    expect(smileIDSampleDetailsSatisfy(named, smileIDSampleRequirementDefaults)).toBe(true);
    expect(smileIDSampleDetailsSatisfy({ ...named, phone: '0700000000' }, smileIDSampleRequirementDefaults)).toBe(false);
  });
});
