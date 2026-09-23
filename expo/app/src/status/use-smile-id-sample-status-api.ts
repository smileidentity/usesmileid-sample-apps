import {
  UseSmileIDSampleStatus,
  smileIDSampleEnvironmentBaseUrl,
  type UseSmileIDSampleJobStatusSource,
  type UseSmileIDSampleStatusRefresh,
} from '@smileid/sample-ui';

/// Ten seconds, the same on every platform, so a dead network ends the spinner rather than holding it.
const TIMEOUT_MILLIS = 10_000;

/// Percent-encoded as one path segment, or a `/`, `?` or `#` would change which request the token is sent with.
export const smileIDSampleStatusUrl = (jobId: string, sandbox: boolean): string | null => {
  const segment = encodeURIComponent(jobId);
  if (segment.length === 0) return null;
  return `${smileIDSampleEnvironmentBaseUrl(sandbox ? 'sandbox' : 'production')}v3/status/${segment}`;
};

/// The HTTP code and body onto an outcome. Pure, so the branch table is unit-testable.
export const smileIDSampleStatusOutcome = (code: number, body: unknown): UseSmileIDSampleStatusRefresh => {
  const response = body as { status?: unknown; message?: unknown } | null;
  if (response === null || typeof response !== 'object' || code < 200 || code >= 300) {
    return { kind: 'failed', reason: `HTTP ${code}` };
  }
  if (typeof response.status !== 'string' || typeof response.message !== 'string') {
    return { kind: 'failed', reason: `HTTP ${code}` };
  }
  if (response.status === 'processing') return { kind: 'stillProcessing' };
  const status = statusFor(response.status);
  if (status === null) return { kind: 'failed', reason: `Unrecognised status '${response.status}'` };
  return { kind: 'updated', status, message: response.message, httpCode: code };
};

/// Five API states onto the four badges the design draws: `error` lands on Blocked and leans on the server's message.
const statusFor = (status: string): UseSmileIDSampleStatus | null => {
  switch (status) {
    case 'clear':
      return UseSmileIDSampleStatus.Clear;
    case 'attention':
      return UseSmileIDSampleStatus.Attention;
    case 'block':
    case 'error':
      return UseSmileIDSampleStatus.Blocked;
    default:
      return null;
  }
};

/// `GET /v3/status/{jobId}` — the partner's own call: the SDK stops at the 202 that creates the job.
export const smileIDSampleStatusApi: UseSmileIDSampleJobStatusSource = {
  check: async (jobId, token, sandbox) => {
    const url = smileIDSampleStatusUrl(jobId, sandbox);
    if (url === null) throw new TypeError('No job id to ask about');
    const abort = new AbortController();
    const timer = setTimeout(() => abort.abort(), TIMEOUT_MILLIS);
    try {
      // The session's own JWT. Never logged.
      const response = await fetch(url, { headers: { 'SmileID-Token': token }, signal: abort.signal });
      const body: unknown = await response.json().catch(() => null);
      return smileIDSampleStatusOutcome(response.status, body);
    } finally {
      clearTimeout(timer);
    }
  },
};
