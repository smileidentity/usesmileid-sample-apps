import {
  smileIDSampleEnvironments,
  smileIDSampleResultDefaults,
  smileIDSampleResultFields,
} from '../src/model/use-smile-id-sample-result';
import { UseSmileIDSampleTestIds } from '../src/use-smile-id-sample-test-ids';
import { spec } from './spec-file';

type ResultCard = {
  required: string[];
  properties: Record<string, { type: string | string[]; enum?: string[] }>;
};

const schema = spec<ResultCard>('result-card.schema.json');

describe('the result card matches spec/result-card.schema.json', () => {
  it('declares every property the schema names, in schema order', () => {
    expect(smileIDSampleResultFields.map((f) => f.field)).toEqual(Object.keys(schema.properties));
  });

  it('carries a value for every required property', () => {
    const declared = smileIDSampleResultDefaults as unknown as Record<string, unknown>;
    for (const field of schema.required) {
      expect({ [field]: declared[field] ?? null }).not.toEqual({ [field]: null });
    }
  });

  it('allows null only where the schema does', () => {
    const declared = smileIDSampleResultDefaults as unknown as Record<string, unknown>;
    const nullable = Object.entries(schema.properties)
      .filter(([, value]) => Array.isArray(value.type) && value.type.includes('null'))
      .map(([name]) => name);
    expect(Object.keys(declared).filter((name) => declared[name] === null).sort()).toEqual(
      nullable.sort(),
    );
  });

  it('publishes each field under a declared test id', () => {
    const ids = Object.values(UseSmileIDSampleTestIds);
    expect(smileIDSampleResultFields.filter((f) => !ids.includes(f.testId))).toEqual([]);
  });

  it('offers exactly the environments the schema enumerates', () => {
    expect([...smileIDSampleEnvironments]).toEqual(schema.properties.environment?.enum);
  });

  it('defaults a tokenless run to sandbox, which is also every automated run', () => {
    expect(smileIDSampleResultDefaults.environment).toBe('sandbox');
  });

  it('starts both callback counters at zero, so exactly-once is provable by counting', () => {
    expect([
      smileIDSampleResultDefaults.resultCallbackCount,
      smileIDSampleResultDefaults.refreshCallbackCount,
    ]).toEqual([0, 0]);
  });
});
