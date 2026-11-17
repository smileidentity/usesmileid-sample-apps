import { smileIDSampleErrorForFailure } from '../src/state/use-smile-id-sample-failure-row';

/// How a failure the SDK hands `onResult` picks its row of spec/error-handling.json, by what the failure carries.
describe('the row a failure resolves to', () => {
  it('resolves a refused submission by its status', () => {
    expect(smileIDSampleErrorForFailure({ statusCode: 429, errorCode: 'NETWORK_RATE_LIMIT' })?.id).toBe('rateLimited');
    expect(smileIDSampleErrorForFailure({ statusCode: 503, errorCode: 'NETWORK_SERVER_ERROR' })?.id).toBe('serverError');
    expect(smileIDSampleErrorForFailure({ statusCode: 403, message: 'HTTP 403' })?.id).toBe('notEnabled');
  });

  it("tells rows of one status apart by the server's message", () => {
    const idNumber = { statusCode: 400, message: 'Invalid ID number format for the specified country and ID type.' };
    expect(smileIDSampleErrorForFailure(idNumber)?.id).toBe('idNumberInvalid');
    expect(smileIDSampleErrorForFailure({ statusCode: 403, message: 'SDK version not allowed.' })?.id).toBe('sdkVersionNotAllowed');
    expect(smileIDSampleErrorForFailure({ statusCode: 400 })?.id).toBe('requestInvalid');
  });

  it('resolves a 408 by its status, though it carries the timeout code', () => {
    expect(smileIDSampleErrorForFailure({ statusCode: 408, errorCode: 'NETWORK_TIMEOUT' })?.id).toBe('requestInvalid');
  });

  it('resolves a timeout and a lost connection as transport failures', () => {
    expect(smileIDSampleErrorForFailure({ errorCode: 'NETWORK_TIMEOUT' })?.id).toBe('timeout');
    expect(smileIDSampleErrorForFailure({ errorCode: 'NETWORK_CONNECTION_FAILED' })?.id).toBe('noConnection');
  });

  it('has no row for a failure no submission returned', () => {
    expect(smileIDSampleErrorForFailure({ errorCode: 'NETWORK_REQUEST_FAILED' })).toBeNull();
    expect(smileIDSampleErrorForFailure({ errorCode: 'CAMERA_PERMISSION_DENIED' })).toBeNull();
    expect(smileIDSampleErrorForFailure(new Error('the camera could not start'))).toBeNull();
    expect(smileIDSampleErrorForFailure('a string')).toBeNull();
    expect(smileIDSampleErrorForFailure(null)).toBeNull();
  });
});
