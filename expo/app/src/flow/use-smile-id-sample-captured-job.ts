import type { smileIDSampleRunRecorder } from '@smileid/sample-ui';
import type { CapturedJob, JobSubmissionResponse, UseSmileIDResult } from '@smileid/usesmileid';
import { Directory, File } from 'expo-file-system';

/// What the card records for the SDK's terminal result.
export const smileIDSampleRecordResult = (
  recorder: ReturnType<typeof smileIDSampleRunRecorder>,
  result: UseSmileIDResult<JobSubmissionResponse>,
): void => {
  switch (result.status) {
    case 'success':
      recorder.deliver('succeeded', { jobId: result.value.jobId, userId: result.value.userId });
      return;
    case 'failure':
      recorder.deliver('failed', {
        error: result.error instanceof Error ? result.error.message : String(result.error),
      });
      return;
    case 'cancelled':
      recorder.deliver('cancelled');
      return;
    case 'captured':
      recorder.deliver('captured');
      return;
    default: {
      // A status the SDK adds fails the build here, as in a partner's app.
      const unhandled: never = result;
      return unhandled;
    }
  }
};

/// Deletes every file the job lists, then its session directory: this sample forwards nothing, and the SDK never deletes them.
export const smileIDSampleDeleteCapturedFiles = (job: CapturedJob): void => {
  const entries: (File | Directory)[] = [
    job.selfieImage,
    ...job.livenessImages,
    job.frontDocument,
    job.backDocument,
    job.visaDocument,
  ]
    .filter((uri): uri is string => uri !== undefined)
    .map((uri) => new File(uri));
  if (job.sessionDirectory !== undefined) entries.push(new Directory(job.sessionDirectory));
  for (const entry of entries) {
    try {
      if (entry.exists) entry.delete();
    } catch {
      // A file left behind is harmless: the SDK writes each session to a folder of its own.
    }
  }
};
