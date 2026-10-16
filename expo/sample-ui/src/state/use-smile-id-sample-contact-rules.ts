import { UseSmileIDSampleUserField } from '../model/use-smile-id-sample-user-fields';

const PHONE_SEPARATORS = /[\s().-]/g;

/// `value` as it is submitted: trimmed, and a phone number without its separators (spec/contact-rules.json).
export const smileIDSampleContactSubmitted = (field: UseSmileIDSampleUserField, value: string): string => {
  const trimmed = value.trim();
  return field === UseSmileIDSampleUserField.Phone ? trimmed.replace(PHONE_SEPARATORS, '') : trimmed;
};
