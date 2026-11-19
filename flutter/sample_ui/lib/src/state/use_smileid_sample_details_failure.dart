import '../components/use_smileid_sample_banner.dart';
import '../model/use_smileid_sample_error_resolution.dart';
import '../model/use_smileid_sample_job.dart';
import '../model/use_smileid_sample_result.dart';
import '../model/use_smileid_sample_status.dart';
import '../use_smileid_sample_strings.dart';
import 'use_smileid_sample_error_handling.dart';

/// What verification details states: a stored [job]'s `error` or `block`, or with no job the failed run that landed here.
UseSmileIDSampleErrorResolution? useSmileIDSampleDetailsFailure({
  required UseSmileIDSampleJob? job,
  required UseSmileIDSampleErrorResolution? landedRun,
}) {
  if (job == null) return landedRun;
  // The status endpoint returns no reason yet, so every such job resolves as the fallback.
  return job.status == UseSmileIDSampleStatus.error ||
          job.status == UseSmileIDSampleStatus.blocked
      ? UseSmileIDSampleErrorHandling.forReason(null)
      : null;
}

/// What a run that landed with no job states: its row, or the submission fallback when no submission explained the failure.
UseSmileIDSampleErrorResolution? useSmileIDSampleLandedFailure({
  required UseSmileIDSampleFlowStatus status,
  required UseSmileIDSampleErrorResolution? row,
}) => status == UseSmileIDSampleFlowStatus.failed
    ? row ?? UseSmileIDSampleErrorHandling.submissionFallback
    : null;

/// How a failure's banner reads.
extension UseSmileIDSampleErrorResolutionBanner
    on UseSmileIDSampleErrorResolution {
  /// Warning when trying again later can get past the failure, error when the row's own action is Close.
  UseSmileIDSampleBannerTone get bannerTone =>
      action == UseSmileIDSampleErrorAction.exit
      ? UseSmileIDSampleBannerTone.error
      : UseSmileIDSampleBannerTone.warning;
}

/// A failure's message in the app's language.
extension UseSmileIDSampleErrorMessageText on UseSmileIDSampleErrorMessage {
  /// The message, from [strings].
  String text(UseSmileIDSampleStrings strings) => switch (this) {
    UseSmileIDSampleErrorMessage.couldNotStart => strings.errorCouldNotStart,
    UseSmileIDSampleErrorMessage.idNumberInvalid =>
      strings.errorIdNumberInvalid,
    UseSmileIDSampleErrorMessage.serviceNotSetUp =>
      strings.errorServiceNotSetUp,
    UseSmileIDSampleErrorMessage.sessionExpired => strings.errorSessionExpired,
    UseSmileIDSampleErrorMessage.serviceUnavailable =>
      strings.errorServiceUnavailable,
    UseSmileIDSampleErrorMessage.notAvailable => strings.errorNotAvailable,
    UseSmileIDSampleErrorMessage.updateApp => strings.errorUpdateApp,
    UseSmileIDSampleErrorMessage.notFound => strings.errorNotFound,
    UseSmileIDSampleErrorMessage.alreadyStarted => strings.errorAlreadyStarted,
    UseSmileIDSampleErrorMessage.linkExpired => strings.errorLinkExpired,
    UseSmileIDSampleErrorMessage.photosTooLarge => strings.errorPhotosTooLarge,
    UseSmileIDSampleErrorMessage.tooManyAttempts =>
      strings.errorTooManyAttempts,
    UseSmileIDSampleErrorMessage.server => strings.errorServer,
    UseSmileIDSampleErrorMessage.noConnection => strings.errorNoConnection,
    UseSmileIDSampleErrorMessage.timeout => strings.errorTimeout,
    UseSmileIDSampleErrorMessage.photoUnusable => strings.errorPhotoUnusable,
    UseSmileIDSampleErrorMessage.photoRejected => strings.errorPhotoRejected,
    UseSmileIDSampleErrorMessage.documentNotRecognised =>
      strings.errorDocumentNotRecognised,
    UseSmileIDSampleErrorMessage.faceCheckUnavailable =>
      strings.errorFaceCheckUnavailable,
    UseSmileIDSampleErrorMessage.noSavedSelfie => strings.errorNoSavedSelfie,
    UseSmileIDSampleErrorMessage.idNumberNotAccepted =>
      strings.errorIdNumberNotAccepted,
    UseSmileIDSampleErrorMessage.idServiceDown => strings.errorIdServiceDown,
    UseSmileIDSampleErrorMessage.couldNotFinish => strings.errorCouldNotFinish,
    UseSmileIDSampleErrorMessage.notVerified => strings.errorNotVerified,
  };
}
