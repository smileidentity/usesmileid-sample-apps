import type {
  UseSmileIDSampleCatalogueFamily,
  UseSmileIDSampleCountry,
  UseSmileIDSampleDocument,
  UseSmileIDSampleKycIdType,
} from './use-smile-id-sample-id-details';
import { smileIDSampleDocumentListedOn } from './use-smile-id-sample-id-details';
import type { UseSmileIDSampleProduct } from '../model/use-smile-id-sample-product';

/// The family `product`'s form reads, or null for the products that ask for no ID details.
export const smileIDSampleCatalogueFamily = (
  product: UseSmileIDSampleProduct,
): UseSmileIDSampleCatalogueFamily | null => {
  switch (product.id) {
    case 'biometricKyc':
    case 'enhancedKyc':
      return 'kyc';
    case 'documentVerification':
    case 'enhancedDocumentVerification':
      return 'document';
    default:
      return null;
  }
};

/// One picker's list: still arriving, arrived, arrived with nothing the form can use, or failed.
export type UseSmileIDSampleCatalogue<T> =
  | { readonly kind: 'loading' }
  | { readonly kind: 'ready'; readonly items: readonly T[] }
  | { readonly kind: 'empty' }
  | { readonly kind: 'failed'; readonly reason: string };

/// An ID type as `supported_id_types` returns it.
export type UseSmileIDSampleApiIdType = {
  readonly country: string;
  readonly type: string;
  readonly label: string;
  readonly regex: string;
  readonly requiredFields: readonly string[];
};

/// A sub-type as `supported_documents` returns it.
type UseSmileIDSampleApiSubType = {
  readonly id: string;
  readonly name: string;
  readonly hasBack: boolean;
  readonly format: number;
  readonly displayStandalone: boolean;
};

/// A document as `supported_documents` returns it.
type UseSmileIDSampleApiDocument = {
  readonly code: string;
  readonly name: string;
  readonly hasBack: boolean;
  readonly format: number;
  readonly subTypes: readonly UseSmileIDSampleApiSubType[];
};

/// One country's entry in `supported_documents`.
export type UseSmileIDSampleApiCountryDocuments = {
  readonly country: UseSmileIDSampleCountry;
  readonly documents: readonly UseSmileIDSampleApiDocument[];
};

/// Both responses a run of the form reads; fetched together because the KYC countries need names from the second.
export type UseSmileIDSampleCatalogueData = {
  readonly idTypes: readonly UseSmileIDSampleApiIdType[];
  readonly documents: readonly UseSmileIDSampleApiCountryDocuments[];
};

/// What the SDK fills in plus the two names the user-details form collects; anything else drops a type.
export const smileIDSampleAllowedRequiredFields: readonly string[] = [
  'country',
  'first_name',
  'id_number',
  'id_type',
  'last_name',
  'partner_id',
  'partner_params',
  'timestamp',
];

/// The ID types `country` offers, with repeated types numbered in API order.
export const smileIDSampleCatalogueIdTypes = (
  all: readonly UseSmileIDSampleApiIdType[],
  country: string,
): UseSmileIDSampleKycIdType[] => {
  const seen = new Map<string, number>();
  const out: UseSmileIDSampleKycIdType[] = [];
  for (const type of all) {
    if (type.country !== country) continue;
    if (!type.requiredFields.every((field) => smileIDSampleAllowedRequiredFields.includes(field))) continue;
    const count = (seen.get(type.type) ?? 0) + 1;
    seen.set(type.type, count);
    out.push({
      id: count === 1 ? type.type : `${type.type}_${count}`,
      type: type.type,
      label: type.label,
      regex: type.regex,
    });
  }
  return out;
};

/// The documents `country` offers, standalone sub-types as their own rows after their parent.
/// `productId` leaves out a row the SDK refuses on it: the Green Book on Enhanced Document Verification.
export const smileIDSampleCatalogueDocuments = (
  all: readonly UseSmileIDSampleApiCountryDocuments[],
  country: string,
  productId: string = 'documentVerification',
): UseSmileIDSampleDocument[] => {
  const entry = all.find((it) => it.country.code === country);
  const out: UseSmileIDSampleDocument[] = [];
  for (const document of entry?.documents ?? []) {
    if (document.code.length === 0) continue;
    out.push({
      code: document.code,
      subType: null,
      name: document.name,
      hasBack: document.hasBack,
      format: document.format,
    });
    for (const sub of document.subTypes) {
      if (!sub.displayStandalone) continue;
      out.push({
        code: document.code,
        subType: sub.id,
        name: sub.name,
        hasBack: sub.hasBack,
        format: sub.format,
      });
    }
  }
  return out.filter((it) => smileIDSampleDocumentListedOn(it, productId));
};

/// The countries `family` offers, named from `supported_documents`; a KYC country it does not name shows by code, after.
export const smileIDSampleCatalogueCountries = (
  data: UseSmileIDSampleCatalogueData,
  family: UseSmileIDSampleCatalogueFamily,
): UseSmileIDSampleCountry[] => {
  const named = data.documents.map((entry) => entry.country);
  if (family === 'document') {
    return named.filter((it) => smileIDSampleCatalogueDocuments(data.documents, it.code).length > 0);
  }
  const listed: string[] = [];
  for (const type of data.idTypes) {
    if (!listed.includes(type.country) && smileIDSampleCatalogueIdTypes(data.idTypes, type.country).length > 0) {
      listed.push(type.country);
    }
  }
  return [
    ...named.filter((it) => listed.includes(it.code)),
    ...listed.filter((code) => !named.some((it) => it.code === code)).map((code) => ({ code, name: code })),
  ];
};

const record = (value: unknown): Record<string, unknown> | null =>
  typeof value === 'object' && value !== null && !Array.isArray(value) ? (value as Record<string, unknown>) : null;

const parse = (body: string): unknown => {
  try {
    return JSON.parse(body);
  } catch {
    return null;
  }
};

/// Decodes a `supported_id_types` body, ignoring unknown keys; null when malformed.
export const smileIDSampleDecodeIdTypes = (body: string): UseSmileIDSampleApiIdType[] | null => {
  const root = record(parse(body));
  if (root === null || !Array.isArray(root.id_types)) return null;
  const out: UseSmileIDSampleApiIdType[] = [];
  for (const raw of root.id_types) {
    const item = record(raw);
    if (
      item === null ||
      typeof item.country !== 'string' ||
      typeof item.type !== 'string' ||
      typeof item.label !== 'string'
    ) {
      continue;
    }
    out.push({
      country: item.country,
      type: item.type,
      label: item.label,
      regex: typeof item.regex === 'string' ? item.regex : '',
      requiredFields: Array.isArray(item.required_fields)
        ? item.required_fields.filter((field): field is string => typeof field === 'string')
        : [],
    });
  }
  return out;
};

const decodeSubType = (raw: unknown): UseSmileIDSampleApiSubType | null => {
  const sub = record(raw);
  if (sub === null || typeof sub.id !== 'string' || typeof sub.name !== 'string') return null;
  return {
    id: sub.id,
    name: sub.name,
    hasBack: typeof sub.has_back === 'boolean' ? sub.has_back : true,
    format: typeof sub.format === 'number' ? sub.format : 1,
    displayStandalone: sub.display_standalone === true,
  };
};

const decodeDocument = (raw: unknown): UseSmileIDSampleApiDocument | null => {
  const item = record(raw);
  if (item === null || typeof item.code !== 'string' || typeof item.name !== 'string') return null;
  return {
    code: item.code,
    name: item.name,
    hasBack: typeof item.has_back === 'boolean' ? item.has_back : true,
    format: typeof item.format === 'number' ? item.format : 1,
    subTypes: Array.isArray(item.sub_types)
      ? item.sub_types.map(decodeSubType).filter((it): it is UseSmileIDSampleApiSubType => it !== null)
      : [],
  };
};

/// Decodes a `supported_documents` body, ignoring unknown keys; null when malformed.
export const smileIDSampleDecodeDocuments = (body: string): UseSmileIDSampleApiCountryDocuments[] | null => {
  const root = record(parse(body));
  if (root === null || !Array.isArray(root.valid_documents)) return null;
  const out: UseSmileIDSampleApiCountryDocuments[] = [];
  for (const raw of root.valid_documents) {
    const item = record(raw);
    const country = record(item?.country);
    if (item === null || country === null || typeof country.code !== 'string' || typeof country.name !== 'string') {
      continue;
    }
    out.push({
      country: { code: country.code, name: country.name },
      documents: Array.isArray(item.id_types)
        ? item.id_types.map(decodeDocument).filter((it): it is UseSmileIDSampleApiDocument => it !== null)
        : [],
    });
  }
  return out;
};
