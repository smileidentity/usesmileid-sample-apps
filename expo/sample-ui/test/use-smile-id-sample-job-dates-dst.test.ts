import { smileIDSampleGroupByDay } from '../src/model/use-smile-id-sample-job-dates';
import type { UseSmileIDSampleJob } from '../src/model/use-smile-id-sample-job';
import { smileIDSampleProducts } from '../src/model/use-smile-id-sample-product';
import { UseSmileIDSampleStatus } from '../src/model/use-smile-id-sample-status';

const zoned = process.env.SAMPLE_TEST_TZ !== undefined;

const job = (createdAtMillis: number): UseSmileIDSampleJob => ({
  id: 'job_dst',
  userId: 'user_dst',
  product: smileIDSampleProducts[0]!,
  status: UseSmileIDSampleStatus.Clear,
  createdAtMillis,
  message: 'Job completed',
  httpStatus: 200,
  sandbox: true,
  sessionId: null,
  partnerId: null,
});

/// Skipped in the default UTC run, which has no clock change; verify.sh runs it under Europe/London.
(zoned ? describe : describe.skip)('the day header across a clock change', () => {
  it('runs in a zone whose spring-forward day is 23 hours long', () => {
    expect((new Date(2026, 2, 30).getTime() - new Date(2026, 2, 29).getTime()) / 3_600_000).toBe(23);
  });

  it('names the day before a 23-hour day as yesterday', () => {
    const now = new Date(2026, 2, 30, 12).getTime();
    const [day] = smileIDSampleGroupByDay([job(new Date(2026, 2, 29, 12).getTime())], now);
    expect(day?.relative).toBe('YESTERDAY');
  });
});
