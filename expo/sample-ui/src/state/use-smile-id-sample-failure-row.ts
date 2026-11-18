import { type UseSmileIDSampleErrorResolution, UseSmileIDSampleTransportFailure } from '../model/use-smile-id-sample-error-resolution';
import { smileIDSampleErrorForStatus, smileIDSampleErrorForTransport } from './use-smile-id-sample-error-handling';

/// What a failure from the SDK carries that picks a row: the HTTP status when the server answered, the server's message and the error code.
type Failure = { readonly statusCode?: unknown; readonly message?: unknown; readonly errorCode?: unknown };

/// The row a failure the SDK hands `onResult` resolves to; null when no submission returned it, such as a camera that could not start.
export const smileIDSampleErrorForFailure = (error: unknown): UseSmileIDSampleErrorResolution | null => {
  if (typeof error !== 'object' || error === null) return null;
  const { statusCode, message, errorCode } = error as Failure;
  if (typeof statusCode === 'number') {
    return smileIDSampleErrorForStatus(statusCode, typeof message === 'string' ? message : null);
  }
  if (errorCode === 'NETWORK_TIMEOUT') return smileIDSampleErrorForTransport(UseSmileIDSampleTransportFailure.Timeout);
  if (errorCode === 'NETWORK_CONNECTION_FAILED') return smileIDSampleErrorForTransport(UseSmileIDSampleTransportFailure.NoConnection);
  return null;
};
