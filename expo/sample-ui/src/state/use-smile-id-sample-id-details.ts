import { smileIDSampleIdNumberAccepts } from './use-smile-id-sample-id-number-hint';
import { UseSmileIDSampleCaptureAs } from '../model/use-smile-id-sample-capture-as';

/// A country from the Smile ID API, named in the locale the request asked for.
export type UseSmileIDSampleCountry = {
  readonly code: string;
  readonly name: string;
};

/// Two regional-indicator letters, which every platform renders as the country's flag; a globe for anything else.
export const smileIDSampleFlag = (code: string): string => {
  const upper = code.toUpperCase();
  if (!/^[A-Z]{2}$/.test(upper)) return '🌍';
  return String.fromCodePoint(...[...upper].map((letter) => 0x1f1e6 + letter.charCodeAt(0) - 0x41));
};

/// A KYC ID type from `supported_id_types`; `id` is `type` with `_2`, `_3` on a repeat (spec/catalogue-rules.json).
export type UseSmileIDSampleKycIdType = {
  readonly id: string;
  /// What the server receives.
  readonly type: string;
  readonly label: string;
  /// The number's format, which the hint and the check are derived from.
  readonly regex: string;
};

/// A document from `supported_documents`; a standalone sub-type row carries `subType` and submits the parent `code`.
export type UseSmileIDSampleDocument = {
  /// What the server receives.
  readonly code: string;
  readonly subType: string | null;
  readonly name: string;
  readonly hasBack: boolean;
  /// The API's undocumented `format`: 3 a booklet, 7 the Green Book, anything else a card.
  readonly format: number;
};

/// The row's id, which suffixes its test id.
export const smileIDSampleDocumentId = (document: UseSmileIDSampleDocument): string =>
  document.subType === null ? document.code : `${document.code}_${document.subType}`;

/// A generic document's capture orientation.
export type UseSmileIDSampleDocumentOrientation = 'landscape' | 'portrait';

export const smileIDSampleOrientations: readonly {
  readonly id: UseSmileIDSampleDocumentOrientation;
  readonly label: string;
}[] = [
  { id: 'landscape', label: 'Landscape' },
  { id: 'portrait', label: 'Portrait' },
];

/// The frame ratios the sheet offers, as width over height; `off` is the SDK's own frame.
export type UseSmileIDSampleAspectRatio = 'off' | 'card' | 'passport' | 'booklet';

export const smileIDSampleAspectRatios: readonly {
  readonly id: UseSmileIDSampleAspectRatio;
  readonly label: string;
  readonly ratio: number | null;
}[] = [
  { id: 'off', label: 'Off', ratio: null },
  { id: 'card', label: 'Card 1.586', ratio: 1.586 },
  { id: 'passport', label: 'Passport 1.309', ratio: 1.309 },
  { id: 'booklet', label: 'Booklet 0.748', ratio: 0.748 },
];

/// What the generic-document sheet builds, as the SDK's GenericDocument takes it.
export type UseSmileIDSampleGenericDocument = {
  readonly displayName: string;
  readonly hasBackSide: boolean;
  readonly orientation: UseSmileIDSampleDocumentOrientation;
  readonly aspectRatio: UseSmileIDSampleAspectRatio;
};

/// The SDK's own generic defaults.
export const smileIDSampleGenericDocumentDefaults: UseSmileIDSampleGenericDocument = {
  displayName: 'Document',
  hasBackSide: true,
  orientation: 'landscape',
  aspectRatio: 'off',
};

/// Which list a product's form reads: the KYC products name an ID type, the document products a document.
export type UseSmileIDSampleCatalogueFamily = 'kyc' | 'document';

/// What the ID-details form has collected, holding whole rows so a flow rebuilt from it needs no catalogue.
export type UseSmileIDSampleIdDetails = {
  readonly country: UseSmileIDSampleCountry | null;
  readonly idType: UseSmileIDSampleKycIdType | null;
  readonly document: UseSmileIDSampleDocument | null;
  readonly captureAs: UseSmileIDSampleCaptureAs;
  readonly genericDocument: UseSmileIDSampleGenericDocument;
  readonly idNumber: string;
};

/// Every field empty; nothing is prefilled, not even from the active profile.
export const smileIDSampleIdDetailsDefaults: UseSmileIDSampleIdDetails = {
  country: null,
  idType: null,
  document: null,
  captureAs: UseSmileIDSampleCaptureAs.Automatic,
  genericDocument: smileIDSampleGenericDocumentDefaults,
  idNumber: '',
};

/// Whether Continue can enable for `family`: every field it shows is set, and the number fits its type.
export const smileIDSampleIdDetailsComplete = (
  details: UseSmileIDSampleIdDetails,
  family: UseSmileIDSampleCatalogueFamily,
): boolean =>
  family === 'document'
    ? details.country !== null && details.document !== null
    : details.country !== null &&
      details.idType !== null &&
      smileIDSampleIdNumberAccepts(details.idType.regex, details.idNumber);

/// Matches on the label, which is what the search field shows, case-folded so a lowercase query still hits.
export const smileIDSampleOptionMatches = (label: string, query: string): boolean =>
  label.toLowerCase().includes(query.trim().toLowerCase());
