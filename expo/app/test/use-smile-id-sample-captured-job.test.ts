import { useSmileIDSampleResultStore, smileIDSampleRunRecorder } from '@smileid/sample-ui';
import type { CapturedJob } from '@smileid/usesmileid';

import { smileIDSampleDeleteCapturedFiles, smileIDSampleRecordResult } from '../src/flow/use-smile-id-sample-captured-job';

/// The paths the mocked file system deleted, files and folders alike.
const mockDeleted: string[] = [];

// A hostless runner has no file system module; this records what the sample asks it to delete.
jest.mock('expo-file-system', () => {
  class MockEntry {
    readonly uri: string;
    constructor(mockUri: string) {
      this.uri = mockUri;
    }
    get exists() {
      return !this.uri.includes('missing');
    }
    delete() {
      if (this.uri.includes('refused')) throw new Error('refused');
      mockDeleted.push(this.uri);
    }
  }
  return { File: MockEntry, Directory: MockEntry };
});

const job = (overrides: Partial<CapturedJob> = {}): CapturedJob => ({
  jobType: 4,
  sessionId: 'session',
  livenessImages: [],
  headers: {},
  encryptedPackage: '00',
  packageNonce: '00',
  packageTag: '00',
  ...overrides,
}) as CapturedJob;

beforeEach(() => {
  mockDeleted.length = 0;
  useSmileIDSampleResultStore.getState().reset();
});

describe('a captured job', () => {
  it('is recorded as captured, not as a failure', () => {
    const recorder = smileIDSampleRunRecorder({
      scenario: 'normal',
      theme: 'brandDefault',
      route: 'fullscreen',
      environment: 'sandbox',
    });

    smileIDSampleRecordResult(recorder, { status: 'captured', job: job() });

    const result = useSmileIDSampleResultStore.getState().result;
    expect(result.jobStatus).toBe('captured');
    expect(result.lastError).toBeNull();
    expect(result.jobId).toBeNull();
    expect(result.resultCallbackCount).toBe(1);
  });

  it('has its files and session directory deleted, since this sample forwards nothing', () => {
    smileIDSampleDeleteCapturedFiles(
      job({
        sessionDirectory: 'file:///data/UseSmileID/session',
        selfieImage: 'file:///data/UseSmileID/session/selfie.jpg',
        livenessImages: ['file:///data/UseSmileID/session/liveness.jpg'],
        frontDocument: 'file:///data/elsewhere/front.jpg',
        backDocument: 'file:///data/missing/back.jpg',
      }),
    );

    expect(mockDeleted).toEqual([
      'file:///data/UseSmileID/session/selfie.jpg',
      'file:///data/UseSmileID/session/liveness.jpg',
      'file:///data/elsewhere/front.jpg',
      'file:///data/UseSmileID/session',
    ]);
  });

  it('skips a delete the file system refuses and goes on with the rest', () => {
    expect(() =>
      smileIDSampleDeleteCapturedFiles(
        job({
          sessionDirectory: 'file:///data/UseSmileID/session',
          selfieImage: 'file:///data/refused/selfie.jpg',
        }),
      ),
    ).not.toThrow();
    expect(mockDeleted).toEqual(['file:///data/UseSmileID/session']);
  });
});
