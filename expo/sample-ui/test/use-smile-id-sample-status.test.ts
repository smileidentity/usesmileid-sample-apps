import {
  smileIDSampleJobFilters,
  smileIDSampleJobFrom,
  smileIDSampleJobMatches,
  type UseSmileIDSampleJob,
} from '../src/model/use-smile-id-sample-job';
import {
  UseSmileIDSampleStatus,
  smileIDSampleStatusLabel,
  smileIDSampleStatusRole,
} from '../src/model/use-smile-id-sample-status';
import { smileSoftBadgeFills } from '../src/smile-product-hues';
import { smileDarkColors, smileLightColors } from '../src/theme/smile-colors';
import { UseSmileIDSampleStrings } from '../src/use-smile-id-sample-strings';

const statuses = Object.values(UseSmileIDSampleStatus);

const job = (status: UseSmileIDSampleStatus): UseSmileIDSampleJob => ({
  id: 'job_00',
  userId: 'user_00',
  product: smileIDSampleJobFrom({ id: 'job_00' })!.product,
  status,
  createdAtMillis: 0,
  message: '',
  httpStatus: 200,
  sandbox: true,
  sessionId: null,
  partnerId: null,
});

/// Every job status, one table each: its label, its stored value, its chips and its pill's fill.
describe('every job status', () => {
  it('reads in Title case', () => {
    const en = UseSmileIDSampleStrings.forLanguage('en');
    expect(statuses.map((status) => smileIDSampleStatusLabel(status, en))).toEqual([
      'Clear',
      'Attention',
      'Blocked',
      'Error',
      'Processing',
    ]);
  });

  it('is stored as its value and reads back as itself', () => {
    for (const status of statuses) {
      const stored = JSON.parse(JSON.stringify(job(status))) as Record<string, unknown>;
      expect(stored.status).toBe(status);
      expect(smileIDSampleJobFrom(stored)?.status).toBe(status);
    }
  });

  it('reads back as Processing from a stored value no status has', () => {
    expect(smileIDSampleJobFrom({ ...job(UseSmileIDSampleStatus.Clear), status: 'Quarantined' })?.status).toBe(
      UseSmileIDSampleStatus.Processing,
    );
  });

  it('is listed by its own chip and by All, and by no other chip', () => {
    const listing = Object.fromEntries(
      statuses.map((status) => [
        status,
        smileIDSampleJobFilters.filter((filter) => smileIDSampleJobMatches(filter, job(status))).map((filter) => filter.id),
      ]),
    );
    expect(listing).toEqual({
      Clear: ['all', 'clear'],
      Attention: ['all', 'attention'],
      Blocked: ['all', 'blocked'],
      Error: ['all', 'error'],
      Processing: ['all'],
    });
  });

  it("draws its pill from its role's soft fill, the same in both schemes", () => {
    expect(statuses.map(smileIDSampleStatusRole)).toEqual(['success', 'warning', 'error', 'neutral', 'info']);
    for (const { badge } of [smileLightColors, smileDarkColors]) {
      expect([
        badge.successBackground,
        badge.successText,
        badge.warningBackground,
        badge.warningText,
        badge.errorBackground,
        badge.errorText,
        badge.neutralBackground,
        badge.neutralText,
        badge.infoBackground,
        badge.infoText,
      ]).toEqual(
        ['success', 'warning', 'error', 'neutral', 'info'].flatMap((role) => [
          smileSoftBadgeFills[role]!.background,
          smileSoftBadgeFills[role]!.text,
        ]),
      );
    }
  });
});
