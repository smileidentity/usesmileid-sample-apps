import type { UseSmileIDSampleJob } from './use-smile-id-sample-job';

const MILLIS_PER_DAY = 24 * 60 * 60 * 1000;

/// A day of jobs under one header, which is the shape the verifications list renders.
export type UseSmileIDSampleJobDay = {
  readonly relative: string;
  readonly absolute: string;
  readonly jobs: readonly UseSmileIDSampleJob[];
};

/// Midnight of the day the value falls in, so a consumer can read the clock coarsely. Idempotent.
export const smileIDSampleStartOfDay = (millis: number): number => {
  const date = new Date(millis);
  date.setHours(0, 0, 0, 0);
  return date.getTime();
};

const dayFormat = (locale?: string) =>
  new Intl.DateTimeFormat(locale, {
    weekday: 'short',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });

/// Groups jobs by calendar day, newest first. Locale-formatted, so it must not be a hardcoded string.
export const smileIDSampleGroupByDay = (
  jobs: readonly UseSmileIDSampleJob[],
  nowMillis: number,
  locale?: string,
): readonly UseSmileIDSampleJobDay[] => {
  const format = dayFormat(locale);
  const today = smileIDSampleStartOfDay(nowMillis);
  const buckets = new Map<number, UseSmileIDSampleJob[]>();
  for (const job of [...jobs].sort((a, b) => b.createdAtMillis - a.createdAtMillis)) {
    const day = smileIDSampleStartOfDay(job.createdAtMillis);
    const bucket = buckets.get(day);
    if (bucket === undefined) buckets.set(day, [job]);
    else bucket.push(job);
  }
  return [...buckets.entries()]
    .sort(([a], [b]) => b - a)
    .map(([day, rows]) => ({
      // A day with no relative word renders the absolute date alone; the header adds no second copy.
      relative: day === today ? 'TODAY' : day === today - MILLIS_PER_DAY ? 'YESTERDAY' : '',
      absolute: format.format(new Date(day)).toUpperCase(),
      jobs: rows,
    }));
};

/// One formatter for the whole list: the list shows a wall-clock time where the countdown shows m:ss.
export const smileIDSampleTimeLabels = (
  jobs: readonly UseSmileIDSampleJob[],
  locale?: string,
): Readonly<Record<string, string>> => {
  const format = new Intl.DateTimeFormat(locale, {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  });
  const labels: Record<string, string> = {};
  for (const job of jobs) labels[job.id] = format.format(new Date(job.createdAtMillis));
  return labels;
};

/// ISO-8601 in UTC, matching the design's row: a machine-readable value, not a display date.
export const smileIDSampleCreatedAtLabel = (job: UseSmileIDSampleJob): string =>
  new Date(job.createdAtMillis).toISOString().replace(/\.(\d{3})Z$/, '.$1Z');
