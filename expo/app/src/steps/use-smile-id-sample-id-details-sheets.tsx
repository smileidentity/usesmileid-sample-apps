import {
  CaptureAsSheet,
  CountryPickerSheet,
  DocumentPickerSheet,
  GenericDocumentSheet,
  IdTypePickerSheet,
  UseSmileIDSampleCaptureAs,
  smileIDSampleCatalogueCountriesOf,
  smileIDSampleCatalogueDocumentsOf,
  smileIDSampleCatalogueFamily,
  smileIDSampleCatalogueIdTypesOf,
  smileIDSampleProductFrom,
  smileIDSampleResolvedCaptureAs,
  useSmileIDSampleFormsStore,
} from '@smileid/sample-ui';
import { useState } from 'react';

import { smileIDSampleCatalogueStore } from '../catalogue/use-smile-id-sample-catalogue';
import {
  smileIDSampleRunProductId,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { UseSmileIDSampleLeave } from '../navigation/use-smile-id-sample-leave';
import { useLaunchArgs } from '../use-smile-id-sample-launch';

/// The product of the run the picker's form belongs to.
const useRunProductId = (scope: UseSmileIDSampleStepScope): string | undefined =>
  smileIDSampleRunProductId(useSmileIDSampleEngine(), scope.entry);

/// The country picker over the ID-details form.
export const UseSmileIDSampleCountryPickerStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const productId = useRunProductId(scope);
  const [query, setQuery] = useState('');
  const product = smileIDSampleProductFrom(productId);
  const family = (product === null ? null : smileIDSampleCatalogueFamily(product)) ?? 'kyc';
  const store = smileIDSampleCatalogueStore(useLaunchArgs().catalogue);
  const catalogue = store();
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.country);
  const setCountry = useSmileIDSampleFormsStore((state) => state.setCountry);

  return (
    <CountryPickerSheet
      catalogue={smileIDSampleCatalogueCountriesOf(catalogue, family, productId)}
      selected={selected}
      query={query}
      onQueryChange={setQuery}
      onSelect={(country) => {
        setCountry(country);
        scope.navigator.back();
      }}
      onRetry={() => store.getState().retry()}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The ID type picker, which needs a country first: a link that opens it without one leaves.
export const UseSmileIDSampleIdTypePickerStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const [query, setQuery] = useState('');
  const store = smileIDSampleCatalogueStore(useLaunchArgs().catalogue);
  const catalogue = store();
  const country = useSmileIDSampleFormsStore((state) => state.idDetails.country);
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.idType);
  const setIdType = useSmileIDSampleFormsStore((state) => state.setIdType);

  if (country === null) return <UseSmileIDSampleLeave onLeave={() => scope.navigator.back()} />;

  return (
    <IdTypePickerSheet
      country={country}
      catalogue={smileIDSampleCatalogueIdTypesOf(catalogue, country.code)}
      selected={selected}
      query={query}
      onQueryChange={setQuery}
      onSelect={(idType) => {
        setIdType(idType);
        scope.navigator.back();
      }}
      onRetry={() => store.getState().retry()}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The document picker, which needs a country first: a link that opens it without one leaves.
export const UseSmileIDSampleDocumentPickerStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const productId = useRunProductId(scope);
  const [query, setQuery] = useState('');
  const store = smileIDSampleCatalogueStore(useLaunchArgs().catalogue);
  const catalogue = store();
  const country = useSmileIDSampleFormsStore((state) => state.idDetails.country);
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.document);
  const setDocument = useSmileIDSampleFormsStore((state) => state.setDocument);

  if (country === null) return <UseSmileIDSampleLeave onLeave={() => scope.navigator.back()} />;

  return (
    <DocumentPickerSheet
      country={country}
      catalogue={smileIDSampleCatalogueDocumentsOf(catalogue, country.code, productId)}
      selected={selected}
      query={query}
      onQueryChange={setQuery}
      onSelect={(document) => {
        setDocument(document);
        scope.navigator.back();
      }}
      onRetry={() => store.getState().retry()}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The capture-as sheet, which needs a document first; generic document hands over to its own sheet in its place.
export const UseSmileIDSampleCaptureAsStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const document = useSmileIDSampleFormsStore((state) => state.idDetails.document);
  const selected = useSmileIDSampleFormsStore((state) => state.idDetails.captureAsOverride);
  const genericDocument = useSmileIDSampleFormsStore((state) => state.idDetails.genericDocument);
  const setCaptureAs = useSmileIDSampleFormsStore((state) => state.setCaptureAs);

  if (document === null) return <UseSmileIDSampleLeave onLeave={() => scope.navigator.back()} />;

  return (
    <CaptureAsSheet
      selected={selected}
      matched={smileIDSampleResolvedCaptureAs(document, null, genericDocument)}
      onSelect={(captureAs) => {
        // Generic document is kept by its own sheet; the others are kept at once.
        if (captureAs === UseSmileIDSampleCaptureAs.GenericDocument) {
          scope.navigator.go('genericDocument', undefined, scope.entry.id);
          return;
        }
        setCaptureAs(captureAs);
        scope.navigator.back();
      }}
      onDismiss={() => scope.navigator.back()}
    />
  );
};

/// The generic-document sheet over the ID-details form.
export const UseSmileIDSampleGenericDocumentStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const initial = useSmileIDSampleFormsStore((state) => state.idDetails.genericDocument);
  const setGenericDocument = useSmileIDSampleFormsStore((state) => state.setGenericDocument);
  return (
    <GenericDocumentSheet
      initial={initial}
      onDone={(genericDocument) => {
        setGenericDocument(genericDocument);
        scope.navigator.back();
      }}
      onDismiss={() => scope.navigator.back()}
    />
  );
};
