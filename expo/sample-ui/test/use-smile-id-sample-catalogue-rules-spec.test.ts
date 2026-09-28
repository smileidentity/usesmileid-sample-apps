import {
  smileIDSampleAllowedRequiredFields,
  smileIDSampleCatalogueCountries,
  smileIDSampleCatalogueDocuments,
  smileIDSampleCatalogueIdTypes,
  smileIDSampleDecodeDocuments,
  smileIDSampleDecodeIdTypes,
} from '../src/state/use-smile-id-sample-catalogue';
import type { UseSmileIDSampleCatalogueFamily } from '../src/state/use-smile-id-sample-id-details';
import { catalogueData } from './catalogue-fixtures';
import { spec } from './spec-file';

type Section = {
  cases: {
    name: string;
    country?: string;
    family?: string;
    input: unknown;
    expected: unknown;
  }[];
};
type Rules = {
  idTypes: Section & { allowedRequiredFields: string[] };
  documents: Section;
  countries: Section;
};

const rules = spec<Rules>('catalogue-rules.json');

/// spec/catalogue-rules.json: the pure rules that turn the two responses into picker rows.
describe('catalogue rules', () => {
  it("allow the spec's required fields", () => {
    expect([...smileIDSampleAllowedRequiredFields].sort()).toEqual([...rules.idTypes.allowedRequiredFields].sort());
  });

  it.each(rules.idTypes.cases.map((c) => [c.name, c] as const))('id types: %s', (_, c) => {
    const all = smileIDSampleDecodeIdTypes(JSON.stringify({ id_types: c.input }))!;
    expect(smileIDSampleCatalogueIdTypes(all, c.country!).map(({ id, type, label }) => ({ id, type, label }))).toEqual(
      c.expected,
    );
  });

  it.each(rules.documents.cases.map((c) => [c.name, c] as const))('documents: %s', (_, c) => {
    const all = smileIDSampleDecodeDocuments(JSON.stringify({ valid_documents: c.input }))!;
    expect(
      smileIDSampleCatalogueDocuments(all, c.country!).map((it) => ({
        id: it.subType === null ? it.code : `${it.code}_${it.subType}`,
        code: it.code,
        subType: it.subType,
        name: it.name,
        hasBack: it.hasBack,
        format: it.format,
      })),
    ).toEqual(c.expected);
  });

  it.each(rules.countries.cases.map((c) => [c.name, c] as const))('countries: %s', (_, c) => {
    const input = c.input as string | { supported_id_types: unknown; supported_documents: unknown };
    const data =
      typeof input === 'string'
        ? catalogueData
        : {
            idTypes: smileIDSampleDecodeIdTypes(JSON.stringify(input.supported_id_types))!,
            documents: smileIDSampleDecodeDocuments(JSON.stringify(input.supported_documents))!,
          };
    expect(smileIDSampleCatalogueCountries(data, c.family as UseSmileIDSampleCatalogueFamily)).toEqual(c.expected);
  });
});
