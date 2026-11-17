/// What a failed verification offers the user; each value is its id in spec/error-handling.json.
export const UseSmileIDSampleErrorAction = {
  Retry: 'retry',
  RetryLater: 'retryLater',
  Recapture: 'recapture',
  FixInput: 'fixInput',
  NewSession: 'newSession',
  Exit: 'exit',
} as const;

export type UseSmileIDSampleErrorAction = (typeof UseSmileIDSampleErrorAction)[keyof typeof UseSmileIDSampleErrorAction];

/// Each action's button, by its key in spec/l10n/app/, and how many times it is offered; no `maxUses` is no limit.
export const smileIDSampleErrorActions: Readonly<
  Record<UseSmileIDSampleErrorAction, { readonly buttonKey: string; readonly maxUses?: number }>
> = {
  retry: { buttonKey: 'common_try_again' },
  retryLater: { buttonKey: 'common_try_again' },
  recapture: { buttonKey: 'error_action_retake_photo', maxUses: 3 },
  fixInput: { buttonKey: 'error_action_edit_id_number' },
  newSession: { buttonKey: 'error_action_start_again', maxUses: 1 },
  exit: { buttonKey: 'error_action_close' },
};

/// The message a failure shows; each value is its key in spec/l10n/app/.
export const UseSmileIDSampleErrorMessage = {
  CouldNotStart: 'error_could_not_start',
  IdNumberInvalid: 'error_id_number_invalid',
  ServiceNotSetUp: 'error_service_not_set_up',
  SessionExpired: 'error_session_expired',
  ServiceUnavailable: 'error_service_unavailable',
  NotAvailable: 'error_not_available',
  UpdateApp: 'error_update_app',
  NotFound: 'error_not_found',
  AlreadyStarted: 'error_already_started',
  LinkExpired: 'error_link_expired',
  PhotosTooLarge: 'error_photos_too_large',
  TooManyAttempts: 'error_too_many_attempts',
  Server: 'error_server',
  NoConnection: 'error_no_connection',
  Timeout: 'error_timeout',
  PhotoUnusable: 'error_photo_unusable',
  PhotoRejected: 'error_photo_rejected',
  DocumentNotRecognised: 'error_document_not_recognised',
  FaceCheckUnavailable: 'error_face_check_unavailable',
  NoSavedSelfie: 'error_no_saved_selfie',
  IdNumberNotAccepted: 'error_id_number_not_accepted',
  IdServiceDown: 'error_id_service_down',
  CouldNotFinish: 'error_could_not_finish',
  NotVerified: 'error_not_verified',
} as const;

export type UseSmileIDSampleErrorMessage = (typeof UseSmileIDSampleErrorMessage)[keyof typeof UseSmileIDSampleErrorMessage];

/// A submission the server never answered; each value is its id in spec/error-handling.json.
export const UseSmileIDSampleTransportFailure = {
  NoConnection: 'noConnection',
  Timeout: 'timeout',
} as const;

export type UseSmileIDSampleTransportFailure =
  (typeof UseSmileIDSampleTransportFailure)[keyof typeof UseSmileIDSampleTransportFailure];

/// What a failure resolves to: the message to show and the one action to offer.
export type UseSmileIDSampleErrorResolution = {
  readonly id: string;
  readonly message: UseSmileIDSampleErrorMessage;
  readonly action: UseSmileIDSampleErrorAction;
  /// How long the button stays dimmed before each use, in order.
  readonly backoffSeconds: readonly number[];
  /// How many times the action is offered before Close replaces it; null is no limit.
  readonly maxUses: number | null;
  /// Whether the button also stays dimmed while the device is offline.
  readonly waitsForConnection: boolean;
};
