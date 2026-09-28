import {
  smileIDSampleCompiled,
  smileIDSampleIdNumberAccepts,
  smileIDSampleIdNumberError,
  smileIDSampleIdNumberExample,
  smileIDSampleIdNumberPlaceholder,
} from '../src/state/use-smile-id-sample-id-number-hint';
import { spec } from './spec-file';

const { cases } = spec<{ cases: { regex: string; hint: string | null }[] }>('id-number-hints.json');

/// spec/id-number-hints.json: the example each regex yields, and the check the field runs.
describe('ID number hints', () => {
  it('has cases inside and outside the subset', () => {
    expect(cases.some((c) => c.hint !== null)).toBe(true);
    expect(cases.some((c) => c.hint === null)).toBe(true);
  });

  it.each(cases.map((c) => [c.regex, c.hint] as const))('%s', (regex, hint) => {
    expect(smileIDSampleCompiled(regex)).not.toBeNull();
    expect(smileIDSampleIdNumberExample(regex)).toBe(hint);
    if (hint !== null) expect(smileIDSampleIdNumberAccepts(regex, hint)).toBe(true);
  });

  it('trims the number and matches the whole regex', () => {
    expect(smileIDSampleIdNumberAccepts('^[0-9]{1,9}$', ' 12345678 ')).toBe(true);
    expect(smileIDSampleIdNumberAccepts('^[0-9]{1,9}$', 'AO12345678')).toBe(false);
    expect(smileIDSampleIdNumberAccepts('^[0-9]{1,9}$', '')).toBe(false);
  });

  it('checks nothing against a regex this engine cannot compile', () => {
    const type = { id: 'X', type: 'X', label: 'Tax number', regex: '^[0-9' };
    expect(smileIDSampleIdNumberAccepts('^[0-9', 'anything')).toBe(true);
    expect(smileIDSampleIdNumberPlaceholder(type)).toBe('Enter your Tax number');
    expect(smileIDSampleIdNumberError(type, 'anything')).toBeNull();
  });

  it('checks nothing for a type with no regex, rather than locking Continue', () => {
    const type = { id: 'X', type: 'X', label: 'Tax number', regex: '' };
    expect(smileIDSampleIdNumberAccepts('', '12345')).toBe(true);
    expect(smileIDSampleIdNumberPlaceholder(type)).toBe('Enter your Tax number');
    expect(smileIDSampleIdNumberError(type, '12345')).toBeNull();
  });

  it('waits for a type, then shows the example', () => {
    expect(smileIDSampleIdNumberPlaceholder(null)).toBe('Choose an ID type first');
    const type = {
      id: 'NIN',
      type: 'NIN',
      label: 'National ID',
      regex: '^[0-9]{11}$',
    };
    expect(smileIDSampleIdNumberPlaceholder(type)).toBe('e.g. 00000000000');
    expect(smileIDSampleIdNumberError(type, '123')).toBe("Doesn't match the National ID format, e.g. 00000000000");
  });
});
