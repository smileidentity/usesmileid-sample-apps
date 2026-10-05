import type { KeyboardTypeOptions, TextInputProps } from 'react-native';

import type { UseSmileIDSampleUserDetails } from '../state/use-smile-id-sample-profiles';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

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
  readonly title: (strings: UseSmileIDSampleStrings) => string;
  /// The title, marked optional where the design does; the row appends any asterisk.
  readonly label: (strings: UseSmileIDSampleStrings) => string;
  readonly placeholder: (strings: UseSmileIDSampleStrings) => string;
  readonly required: boolean;
};

/// The four rows in the order both forms draw them.
export const smileIDSampleUserFields: readonly UseSmileIDSampleUserFieldSpec[] = [
  {
    id: UseSmileIDSampleUserField.FirstName,
    title: (strings) => strings.userFieldFirstName,
    label: (strings) => strings.userFieldFirstName,
    placeholder: (strings) => strings.userFieldFirstNamePlaceholder,
    required: true,
  },
  {
    id: UseSmileIDSampleUserField.LastName,
    title: (strings) => strings.userFieldLastName,
    label: (strings) => strings.userFieldLastName,
    placeholder: (strings) => strings.userFieldLastNamePlaceholder,
    required: true,
  },
  {
    id: UseSmileIDSampleUserField.Email,
    title: (strings) => strings.userFieldEmail,
    label: (strings) => strings.userFieldEmailOptional,
    placeholder: (strings) => strings.userFieldEmailPlaceholder,
    required: false,
  },
  {
    id: UseSmileIDSampleUserField.Phone,
    title: (strings) => strings.userFieldPhone,
    label: (strings) => strings.userFieldPhoneOptional,
    placeholder: (strings) => strings.userFieldPhonePlaceholder,
    required: false,
  },
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

/// The keyboard each field wants: names capitalised, the email keyboard uncorrected, the dial pad for phone.
export const smileIDSampleUserFieldKeyboard = (
  field: UseSmileIDSampleUserField,
): {
  readonly keyboardType: KeyboardTypeOptions;
  readonly autoCapitalize: TextInputProps['autoCapitalize'];
  readonly autoCorrect: boolean;
} => {
  if (field === UseSmileIDSampleUserField.Email) {
    return { keyboardType: 'email-address', autoCapitalize: 'none', autoCorrect: false };
  }
  if (field === UseSmileIDSampleUserField.Phone) {
    return { keyboardType: 'phone-pad', autoCapitalize: 'none', autoCorrect: false };
  }
  return { keyboardType: 'default', autoCapitalize: 'words', autoCorrect: false };
};
