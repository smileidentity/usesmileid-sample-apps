import { UseSmileIDSampleUserField } from '../model/use-smile-id-sample-user-fields';
import type { UseSmileIDSampleUserDetails } from './use-smile-id-sample-profiles';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

/// Which contact value the server would refuse (spec/contact-rules.json).
export type UseSmileIDSampleContactProblem = 'email' | 'phone';

/// The line under the field, in the app's language.
export const smileIDSampleContactProblemText = (
  problem: UseSmileIDSampleContactProblem,
  strings: UseSmileIDSampleStrings,
): string => (problem === 'email' ? strings.userFieldEmailError : strings.userFieldPhoneError);

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const PHONE_SEPARATORS = /[\s().-]/g;
const PHONE = /^\+[1-9][0-9]{6,14}$/;

/// `value` as it is submitted: trimmed, and a phone number without its separators.
export const smileIDSampleContactSubmitted = (field: UseSmileIDSampleUserField, value: string): string => {
  const trimmed = value.trim();
  return field === UseSmileIDSampleUserField.Phone ? trimmed.replace(PHONE_SEPARATORS, '') : trimmed;
};

/// Why `value` would fail the job as `field`, or null when it would pass; blank always passes.
export const smileIDSampleContactProblem = (
  field: UseSmileIDSampleUserField,
  value: string,
): UseSmileIDSampleContactProblem | null => {
  const submitted = smileIDSampleContactSubmitted(field, value);
  if (submitted.length === 0) return null;
  if (field === UseSmileIDSampleUserField.Email) return EMAIL.test(submitted) ? null : 'email';
  if (field === UseSmileIDSampleUserField.Phone) return PHONE.test(submitted) ? null : 'phone';
  return null;
};

/// Why the email or phone would fail the job, email first; null when both would pass.
export const smileIDSampleDetailsContactProblem = (
  details: Pick<UseSmileIDSampleUserDetails, 'email' | 'phone'>,
): UseSmileIDSampleContactProblem | null =>
  smileIDSampleContactProblem(UseSmileIDSampleUserField.Email, details.email) ??
  smileIDSampleContactProblem(UseSmileIDSampleUserField.Phone, details.phone);
