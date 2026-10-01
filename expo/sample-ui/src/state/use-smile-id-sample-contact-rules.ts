import { UseSmileIDSampleUserField } from '../model/use-smile-id-sample-user-fields';
import type { UseSmileIDSampleUserDetails } from './use-smile-id-sample-profiles';

/// Shown for an email the server would refuse (spec/contact-rules.json).
export const SMILE_ID_SAMPLE_EMAIL_ERROR = 'Enter an email like name@company.com.';
/// Shown for a phone number the server would refuse (spec/contact-rules.json).
export const SMILE_ID_SAMPLE_PHONE_ERROR = 'Enter the number with its country code, like +254 700 000 000.';

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const PHONE_SEPARATORS = /[\s().-]/g;
const PHONE = /^\+[1-9][0-9]{6,14}$/;

/// `value` as it is submitted: trimmed, and a phone number without its separators.
export const smileIDSampleContactSubmitted = (field: UseSmileIDSampleUserField, value: string): string => {
  const trimmed = value.trim();
  return field === UseSmileIDSampleUserField.Phone ? trimmed.replace(PHONE_SEPARATORS, '') : trimmed;
};

/// Why `value` would fail the job as `field`, or null when it would pass; blank always passes.
export const smileIDSampleContactProblem = (field: UseSmileIDSampleUserField, value: string): string | null => {
  const submitted = smileIDSampleContactSubmitted(field, value);
  if (submitted.length === 0) return null;
  if (field === UseSmileIDSampleUserField.Email) return EMAIL.test(submitted) ? null : SMILE_ID_SAMPLE_EMAIL_ERROR;
  if (field === UseSmileIDSampleUserField.Phone) return PHONE.test(submitted) ? null : SMILE_ID_SAMPLE_PHONE_ERROR;
  return null;
};

/// Why the email or phone would fail the job, email first; null when both would pass.
export const smileIDSampleDetailsContactProblem = (
  details: Pick<UseSmileIDSampleUserDetails, 'email' | 'phone'>,
): string | null =>
  smileIDSampleContactProblem(UseSmileIDSampleUserField.Email, details.email) ??
  smileIDSampleContactProblem(UseSmileIDSampleUserField.Phone, details.phone);
