import type { UseSmileIDSampleUserDetails } from '../state/use-smile-id-sample-profiles';

/// Which user-details row changed, so a form reports one callback rather than four.
export const UseSmileIDSampleUserField = {
  FirstName: 'firstName',
  LastName: 'lastName',
  Email: 'email',
  Phone: 'phone',
} as const;

export type UseSmileIDSampleUserField =
  (typeof UseSmileIDSampleUserField)[keyof typeof UseSmileIDSampleUserField];

/// A row's own copy, which both the consent form and the profile defaults draw from.
export type UseSmileIDSampleUserFieldSpec = {
  readonly id: UseSmileIDSampleUserField;
  readonly label: string;
  readonly placeholder: string;
  readonly required: boolean;
};

/// The four rows in the order both forms draw them.
export const smileIDSampleUserFields: readonly UseSmileIDSampleUserFieldSpec[] = [
  { id: UseSmileIDSampleUserField.FirstName, label: 'First name', placeholder: 'Add first name', required: true },
  { id: UseSmileIDSampleUserField.LastName, label: 'Last name', placeholder: 'Add last name', required: true },
  { id: UseSmileIDSampleUserField.Email, label: 'Email (optional)', placeholder: 'name@company.com', required: false },
  { id: UseSmileIDSampleUserField.Phone, label: 'Phone (optional)', placeholder: '+254 700 000 000', required: false },
];

export const smileIDSampleUserFieldRead = (
  field: UseSmileIDSampleUserField,
  details: UseSmileIDSampleUserDetails,
): string => details[field];

export const smileIDSampleUserFieldWrite = (
  field: UseSmileIDSampleUserField,
  details: UseSmileIDSampleUserDetails,
  value: string,
): UseSmileIDSampleUserDetails => ({ ...details, [field]: value });

/// The design's own rule: "First and last name are required."
export const smileIDSampleUserDetailsComplete = (details: UseSmileIDSampleUserDetails): boolean =>
  details.firstName.trim().length > 0 && details.lastName.trim().length > 0;
