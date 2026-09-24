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

/// What a run was entered with; the card records it rather than re-reading the settings.
export type UseSmileIDSampleRunContext = {
  readonly scenario: string;
  readonly theme: string;
  readonly route: UseSmileIDSampleFlowRoute;
  readonly environment: UseSmileIDSampleEnvironment;
};

const entered = (result: UseSmileIDSampleResult, run: UseSmileIDSampleRunContext) => ({
  ...result,
  activeScenario: run.scenario,
  activeTheme: run.theme,
  route: run.route,
  environment: run.environment,
});

/// A run starting; both counts reset, so "exactly once" holds per run rather than per launch.
export const smileIDSampleResultStarted = (
  result: UseSmileIDSampleResult,
  run: UseSmileIDSampleRunContext,
): UseSmileIDSampleResult => ({
  ...entered(result, run),
  jobStatus: 'running',
  resultCallbackCount: 0,
  refreshCallbackCount: 0,
  jobId: null,
  userId: null,
  lastError: null,
});

/// One host result callback; `userId` must be the server's, never a local placeholder.
export const smileIDSampleResultRecorded = (
  result: UseSmileIDSampleResult,
  status: UseSmileIDSampleFlowStatus,
  outcome: { readonly jobId?: string; readonly userId?: string; readonly error?: string } = {},
): UseSmileIDSampleResult => ({
  ...result,
  jobStatus: status,
  resultCallbackCount: result.resultCallbackCount + 1,
  jobId: outcome.jobId ?? null,
  userId: outcome.userId ?? null,
  lastError: outcome.error ?? null,
});

/// The gate refused the run, so the SDK never mounted; not a result callback.
export const smileIDSampleResultBlocked = (
  result: UseSmileIDSampleResult,
  reason: string,
  run: UseSmileIDSampleRunContext,
): UseSmileIDSampleResult => ({
  ...entered(result, run),
  jobStatus: 'failed',
  jobId: null,
  userId: null,
  lastError: reason,
});

/// The launch's selection, shown until a run records the one it actually got.
export const smileIDSampleResultSelecting = (
  result: UseSmileIDSampleResult,
  scenario: string,
  theme: string,
): UseSmileIDSampleResult =>
  result.jobStatus === 'idle' ? { ...result, activeScenario: scenario, activeTheme: theme } : result;
