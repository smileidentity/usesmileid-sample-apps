import {
  smileIDSampleAllowedRequiredFields,
  smileIDSampleCatalogueAdvice,
  smileIDSampleCatalogueCountries,
  smileIDSampleCatalogueAdviceText,
  smileIDSampleCatalogueDefaultAdvice,
  smileIDSampleCatalogueDocuments,
  smileIDSampleCatalogueEnabledCountries,
  smileIDSampleCatalogueEnabledDocuments,
  smileIDSampleCatalogueIdTypes,
  smileIDSampleDecodeDocuments,
  smileIDSampleDecodeEnabledCountries,
  smileIDSampleDecodeIdTypes,
} from '../src/state/use-smile-id-sample-catalogue';
import {
  smileIDSampleCaptureAsTriggerText,
  smileIDSampleCaptureBothSides,
  smileIDSampleGenericDocumentDefaults,
  smileIDSampleIdDetailsDefaults,
  smileIDSampleMatchRowLabel,
  smileIDSampleResolvedCaptureAs,
  type UseSmileIDSampleCatalogueFamily,
  type UseSmileIDSampleDocument,
  type UseSmileIDSampleGenericDocument,
} from '../src/state/use-smile-id-sample-id-details';
import {
  smileIDSampleMatchDocumentId,
  type UseSmileIDSampleCaptureAs,
} from '../src/model/use-smile-id-sample-capture-as';
import { useSmileIDSampleFormsStore } from '../src/state/use-smile-id-sample-forms-store';
import { catalogueData, catalogueFixture } from './catalogue-fixtures';
import { spec } from './spec-file';
import { UseSmileIDSampleStrings } from '../src/use-smile-id-sample-strings';

const strings = UseSmileIDSampleStrings.forLanguage('en');

type Section = {
  cases: {
    name: string;
    country?: string;
    family?: string;
    product?: string;
    input: unknown;
    expected: unknown;
  }[];
};
type Rules = {
  idTypes: Section & { allowedRequiredFields: string[] };
  documents: Section;
  countries: Section;
  enabledDocuments: Section;
  enabledCountries: Section;
  failures: { default: string; cases: { status: number | null; supportingText: string }[] };
  captureAs: {
    triggerPlaceholder: string;
    cases: CaptureAsCase[];
    resets: { cases: ResetCase[] };
  };
};

type Row = Omit<UseSmileIDSampleDocument, 'subType'> & { subType?: string };
type CaptureAsCase = {
  name: string;
  captureAs: string;
  document: Row;
  genericDocument?: UseSmileIDSampleGenericDocument;
  expected: {
    documentType: string;
    displayName?: string;
    hasBackSide?: boolean;
    orientation?: string;
    matched: boolean;
    captureBothSides: boolean;
    triggerText: string;
    matchRowLabel: string;
  };
};
type ResetCase = {
  name: string;
  captureAs: string;
  document: Row;
  change: { document?: Row; country?: { code: string; name: string } };
  expected: string;
};

const row = (it: Row): UseSmileIDSampleDocument => ({ ...it, subType: it.subType ?? null });
const override = (id: string): UseSmileIDSampleCaptureAs | null =>
  id === smileIDSampleMatchDocumentId ? null : (id as UseSmileIDSampleCaptureAs);

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
      smileIDSampleCatalogueDocuments(all, c.country!, c.product).map((it) => ({
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

  const enabledInput = (input: unknown) => {
    const both =
      typeof input === 'string'
        ? catalogueFixture
        : (input as { supported_documents: unknown; services_config: unknown });
    return {
      all: smileIDSampleDecodeDocuments(JSON.stringify(both.supported_documents))!,
      enabled: smileIDSampleDecodeEnabledCountries(JSON.stringify(both.services_config))!,
    };
  };

  it.each(rules.enabledDocuments.cases.map((c) => [c.name, c] as const))('enabled documents: %s', (_, c) => {
    const { all, enabled } = enabledInput(c.input);
    expect(
      smileIDSampleCatalogueEnabledDocuments(all, enabled, c.country!).map((it) => ({
        id: it.subType === null ? it.code : `${it.code}_${it.subType}`,
        code: it.code,
        subType: it.subType,
        name: it.name,
        hasBack: it.hasBack,
        format: it.format,
      })),
    ).toEqual(c.expected);
  });

  it.each(rules.enabledCountries.cases.map((c) => [c.name, c] as const))('enabled countries: %s', (_, c) => {
    const { all, enabled } = enabledInput(c.input);
    expect(smileIDSampleCatalogueEnabledCountries(all, enabled)).toEqual(c.expected);
  });

  it('names the failures the spec names', () => {
    expect(smileIDSampleCatalogueAdviceText(smileIDSampleCatalogueDefaultAdvice, strings)).toBe(rules.failures.default);
    for (const c of rules.failures.cases) {
      expect(smileIDSampleCatalogueAdviceText(smileIDSampleCatalogueAdvice(c.status), strings)).toBe(c.supportingText);
    }
  });

  it.each(rules.captureAs.cases.map((c) => [c.name, c] as const))('capture as: %s', (_, c) => {
    const resolved = smileIDSampleResolvedCaptureAs(
      row(c.document),
      override(c.captureAs),
      c.genericDocument ?? smileIDSampleGenericDocumentDefaults,
    );
    expect(resolved.captureAs === 'genericDocument' ? 'generic' : resolved.captureAs).toBe(c.expected.documentType);
    if (resolved.captureAs === 'genericDocument') {
      expect(resolved.genericDocument.displayName).toBe(c.expected.displayName);
      expect(resolved.genericDocument.hasBackSide).toBe(c.expected.hasBackSide);
      expect(resolved.genericDocument.orientation).toBe(c.expected.orientation);
    }
    expect(resolved.matched).toBe(c.expected.matched);
    expect(smileIDSampleCaptureBothSides(resolved)).toBe(c.expected.captureBothSides);
    expect(smileIDSampleCaptureAsTriggerText(resolved, strings)).toBe(c.expected.triggerText);
    expect(
      smileIDSampleMatchRowLabel(smileIDSampleResolvedCaptureAs(row(c.document), null, smileIDSampleGenericDocumentDefaults), strings),
    ).toBe(c.expected.matchRowLabel);
  });

  it.each(rules.captureAs.resets.cases.map((c) => [c.name, c] as const))('capture as resets: %s', (_, c) => {
    const forms = useSmileIDSampleFormsStore.getState();
    useSmileIDSampleFormsStore.setState({ idDetails: smileIDSampleIdDetailsDefaults });
    forms.setCountry({ code: 'ZA', name: 'South Africa' });
    forms.setDocument(row(c.document));
    forms.setCaptureAs(override(c.captureAs));
    if (c.change.document) forms.setDocument(row(c.change.document));
    if (c.change.country) forms.setCountry(c.change.country);
    expect(useSmileIDSampleFormsStore.getState().idDetails.captureAsOverride).toBe(override(c.expected));
  });

  it('drops a row the product does not list, with its override', () => {
    const greenBook: UseSmileIDSampleDocument = { code: 'IDENTITY_CARD', subType: 'green_book', name: 'Green Book', hasBack: false, format: 7 };
    const forms = useSmileIDSampleFormsStore.getState();
    useSmileIDSampleFormsStore.setState({ idDetails: { ...smileIDSampleIdDetailsDefaults, document: greenBook, captureAsOverride: 'passport' } });
    forms.keepDocumentListedOn('documentVerification');
    expect(useSmileIDSampleFormsStore.getState().idDetails.document).toEqual(greenBook);
    forms.keepDocumentListedOn('enhancedDocumentVerification');
    expect(useSmileIDSampleFormsStore.getState().idDetails.document).toBeNull();
    expect(useSmileIDSampleFormsStore.getState().idDetails.captureAsOverride).toBeNull();
  });

  it("uses the spec's trigger placeholder", () => {
    expect(strings.captureAsMatchDocument).toBe(rules.captureAs.triggerPlaceholder);
  });
});
