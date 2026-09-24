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
  /// The field's title, the one source every screen's label is built from.
  readonly title: string;
  /// The title, marked optional where the design does; the row appends any asterisk.
  readonly label: string;
  readonly placeholder: string;
  readonly required: boolean;
};

/// The four rows in the order both forms draw them.
const field = (
  id: UseSmileIDSampleUserField,
  title: string,
  placeholder: string,
  required: boolean,
): UseSmileIDSampleUserFieldSpec => ({ id, title, label: required ? title : `${title} (optional)`, placeholder, required });

export const smileIDSampleUserFields: readonly UseSmileIDSampleUserFieldSpec[] = [
  field(UseSmileIDSampleUserField.FirstName, 'First name', 'Add first name', true),
  field(UseSmileIDSampleUserField.LastName, 'Last name', 'Add last name', true),
  field(UseSmileIDSampleUserField.Email, 'Email', 'name@company.com', false),
  field(UseSmileIDSampleUserField.Phone, 'Phone', '+254 700 000 000', false),
];

/// One field's spec by id; every id has one.
export const smileIDSampleUserFieldSpec = (id: UseSmileIDSampleUserField): UseSmileIDSampleUserFieldSpec =>
  smileIDSampleUserFields.find((spec) => spec.id === id)!;

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
