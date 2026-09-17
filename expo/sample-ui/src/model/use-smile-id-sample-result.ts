import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';
import type { UseSmileIDSampleFlowRoute } from './use-smile-id-sample-scenario';

/// Where a run submitted, which the token's `api_url` claim decides and nothing can override.
export const smileIDSampleEnvironments = ['sandbox', 'production'] as const;

export type UseSmileIDSampleEnvironment = (typeof smileIDSampleEnvironments)[number];

/// Cancelled and Failed stay separate: a screenshot cannot tell a user backing out from a failure.
export const smileIDSampleFlowStatuses = [
  'idle',
  'running',
  'succeeded',
  'cancelled',
  'failed',
] as const;

export type UseSmileIDSampleFlowStatus = (typeof smileIDSampleFlowStatuses)[number];

/// A snapshot of what the SDK did, mirroring `spec/result-card.schema.json` field for field.
export type UseSmileIDSampleResult = {
  readonly activeScenario: string;
  readonly activeTheme: string;
  readonly route: UseSmileIDSampleFlowRoute;
  /// Where the run submitted, from its token. With the chip gone this is the only surface that proves it.
  readonly environment: UseSmileIDSampleEnvironment;
  readonly jobStatus: UseSmileIDSampleFlowStatus;
  readonly resultCallbackCount: number;
  readonly refreshCallbackCount: number;
  readonly jobId: string | null;
  readonly userId: string | null;
  readonly lastError: string | null;
  /// Read at runtime from the resolved package, which this platform can do and Android cannot.
  readonly sdkVersion: string | null;
};

/// Every card field with the id it publishes under, so the card cannot render a field no flow can read.
export const smileIDSampleResultFields = [
  { field: 'activeScenario', testId: UseSmileIDSampleTestIds.RESULT_ACTIVE_SCENARIO },
  { field: 'activeTheme', testId: UseSmileIDSampleTestIds.RESULT_ACTIVE_THEME },
  { field: 'route', testId: UseSmileIDSampleTestIds.RESULT_ROUTE },
  { field: 'environment', testId: UseSmileIDSampleTestIds.RESULT_ENVIRONMENT },
  { field: 'jobId', testId: UseSmileIDSampleTestIds.RESULT_JOB_ID },
  { field: 'userId', testId: UseSmileIDSampleTestIds.RESULT_USER_ID },
  { field: 'jobStatus', testId: UseSmileIDSampleTestIds.RESULT_JOB_STATUS },
  { field: 'resultCallbackCount', testId: UseSmileIDSampleTestIds.RESULT_RESULT_COUNT },
  { field: 'refreshCallbackCount', testId: UseSmileIDSampleTestIds.RESULT_REFRESH_COUNT },
  { field: 'lastError', testId: UseSmileIDSampleTestIds.RESULT_LAST_ERROR },
  { field: 'sdkVersion', testId: UseSmileIDSampleTestIds.RESULT_SDK_VERSION },
] as const;

/// A tokenless run reads sandbox, which is also every automated run.
export const smileIDSampleResultDefaults: UseSmileIDSampleResult = {
  activeScenario: 'normal',
  activeTheme: 'brandDefault',
  route: 'fullscreen',
  environment: 'sandbox',
  jobStatus: 'idle',
  resultCallbackCount: 0,
  refreshCallbackCount: 0,
  jobId: null,
  userId: null,
  lastError: null,
  sdkVersion: null,
};
