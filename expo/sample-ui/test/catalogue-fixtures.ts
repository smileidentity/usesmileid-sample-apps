import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import {
  smileIDSampleCatalogueCountries,
  smileIDSampleCatalogueDocuments,
  smileIDSampleCatalogueIdTypes,
  smileIDSampleDecodeDocuments,
  smileIDSampleDecodeIdTypes,
  type UseSmileIDSampleCatalogueData,
} from '../src/state/use-smile-id-sample-catalogue';
import type {
  UseSmileIDSampleCatalogueFamily,
  UseSmileIDSampleCountry,
} from '../src/state/use-smile-id-sample-id-details';

/// spec/catalogue-fixture.json, as the fixture source hands it over.
export const catalogueFixture = JSON.parse(
  readFileSync(join(__dirname, '..', '..', '..', 'spec', 'catalogue-fixture.json'), 'utf8'),
) as { supported_id_types: unknown; supported_documents: unknown; services_config: unknown };

/// Both responses, read through the decoder the store runs.
export const catalogueData: UseSmileIDSampleCatalogueData = {
  idTypes: smileIDSampleDecodeIdTypes(JSON.stringify(catalogueFixture.supported_id_types))!,
  documents: smileIDSampleDecodeDocuments(JSON.stringify(catalogueFixture.supported_documents))!,
};

export const KENYA: UseSmileIDSampleCountry = { code: 'KE', name: 'Kenya' };
export const SOUTH_AFRICA: UseSmileIDSampleCountry = {
  code: 'ZA',
  name: 'South Africa',
};

export const fixtureCountries = (family: UseSmileIDSampleCatalogueFamily) =>
  smileIDSampleCatalogueCountries(catalogueData, family);

export const fixtureIdTypes = (country: string) => smileIDSampleCatalogueIdTypes(catalogueData.idTypes, country);

export const fixtureDocuments = (country: string, productId?: string) =>
  smileIDSampleCatalogueDocuments(catalogueData.documents, country, productId);
