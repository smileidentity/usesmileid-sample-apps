import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
  useSmileIDSampleTestIdValues,
} from '../src/use-smile-id-sample-test-ids';
import { spec } from './spec-file';

type TestIds = { prefix: string; ids: Record<string, { id: string }[]> };

const testIdsSpec = spec<TestIds>('test-ids.json');
const specIds = Object.values(testIdsSpec.ids).flatMap((group) => group.map((entry) => entry.id));

describe('test ids match spec/test-ids.json', () => {
  it('declares every id the spec lists', () => {
    expect([...useSmileIDSampleTestIdValues].sort()).toEqual([...specIds].sort());
  });

  it('declares nothing the spec does not list', () => {
    expect(useSmileIDSampleTestIdValues.filter((id) => !specIds.includes(id))).toEqual([]);
  });

  it('carries the spec prefix on every id', () => {
    expect(useSmileIDSampleTestIdValues.filter((id) => !id.startsWith(testIdsSpec.prefix))).toEqual([]);
  });

  it('has no duplicate among the declared ids', () => {
    expect(new Set(useSmileIDSampleTestIdValues).size).toBe(useSmileIDSampleTestIdValues.length);
  });
});

describe('suffixed ids derive from their base id', () => {
  it('appends the caller value to the spec base', () => {
    expect(UseSmileIDSampleSuffixedTestIds.productCard('smartSelfieEnrollment')).toBe(
      'sample_product_card_smartSelfieEnrollment',
    );
    expect(UseSmileIDSampleSuffixedTestIds.filterChip('attention')).toBe('sample_filter_chip_attention');
    expect(UseSmileIDSampleSuffixedTestIds.jobRow(3)).toBe('sample_job_row_3');
  });

  it('folds a coordinate that a resource id cannot carry', () => {
    expect(UseSmileIDSampleSuffixedTestIds.licenseRow('com.usesmileid:usesmileid')).toBe(
      'sample_license_row_com_usesmileid_usesmileid',
    );
  });

  it('starts every suffixed id from a declared base', () => {
    const bases = Object.values(UseSmileIDSampleTestIds);
    const built = [
      UseSmileIDSampleSuffixedTestIds.productCard('x'),
      UseSmileIDSampleSuffixedTestIds.tokenEnvironment('x'),
      UseSmileIDSampleSuffixedTestIds.settingNav('x'),
      UseSmileIDSampleSuffixedTestIds.licenseRow('x'),
      UseSmileIDSampleSuffixedTestIds.licenseText('x'),
      UseSmileIDSampleSuffixedTestIds.licenseLink('x'),
      UseSmileIDSampleSuffixedTestIds.scenarioItem('x'),
      UseSmileIDSampleSuffixedTestIds.themeItem('x'),
      UseSmileIDSampleSuffixedTestIds.filterChip('x'),
      UseSmileIDSampleSuffixedTestIds.filterCount('x'),
      UseSmileIDSampleSuffixedTestIds.jobRow(1),
      UseSmileIDSampleSuffixedTestIds.selectionCheckbox(1),
      UseSmileIDSampleSuffixedTestIds.detailField('x'),
      UseSmileIDSampleSuffixedTestIds.detailCopy('x'),
      UseSmileIDSampleSuffixedTestIds.userDetailsField('x'),
      UseSmileIDSampleSuffixedTestIds.countryOption('x'),
      UseSmileIDSampleSuffixedTestIds.idTypeOption('x'),
      UseSmileIDSampleSuffixedTestIds.profileRow('x'),
      UseSmileIDSampleSuffixedTestIds.profileConfigField('x'),
    ];
    expect(built.filter((id) => !bases.some((base) => id === `${base}_x` || id === `${base}_1`))).toEqual([]);
  });
});
