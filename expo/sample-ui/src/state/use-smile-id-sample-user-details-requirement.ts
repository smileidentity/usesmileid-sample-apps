import type { UseSmileIDSampleTokenBindings } from './use-smile-id-sample-token-decoder';
import type { UseSmileIDSampleUserDetails } from './use-smile-id-sample-profiles';
import { UseSmileIDSampleUserField, type UseSmileIDSampleUserFieldSpec } from '../model/use-smile-id-sample-user-fields';

export type { UseSmileIDSampleTokenBindings };

/// What the form must still collect: the SDK's rule minus what the token binds.
export type UseSmileIDSampleUserDetailsRequirement = {
  readonly firstName: boolean;
  readonly lastName: boolean;
  /// One of email or phone, which is why neither row is individually supplied.
  readonly contact: boolean;
};

/// No token, so the form asks for everything the SDK's own validator would.
export const smileIDSampleRequirementDefaults: UseSmileIDSampleUserDetailsRequirement = {
  firstName: true,
  lastName: true,
  contact: true,
};

/// The requirement a token leaves behind, which is the only thing that lifts a row.
export const smileIDSampleRequirementFrom = (
  bindings: UseSmileIDSampleTokenBindings | null | undefined,
): UseSmileIDSampleUserDetailsRequirement => ({
  firstName: bindings?.givenNames !== true,
  lastName: bindings?.lastName !== true,
  contact: !(bindings?.email === true || bindings?.phoneNumber === true),
});

/// Nothing left to ask, so the form has no reason to appear.
export const smileIDSampleRequirementSatisfied = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
): boolean => !requirement.firstName && !requirement.lastName && !requirement.contact;

/// No relevant binding at all, the one case the SDK's own validator can still decide.
export const smileIDSampleRequirementBindsNothing = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
): boolean => requirement.firstName && requirement.lastName && requirement.contact;

/// Whether the form has collected what the requirement still asks of it.
export const smileIDSampleDetailsSatisfy = (
  details: UseSmileIDSampleUserDetails,
  requirement: UseSmileIDSampleUserDetailsRequirement,
): boolean =>
  (!requirement.firstName || details.firstName.trim().length > 0) &&
  (!requirement.lastName || details.lastName.trim().length > 0) &&
  (!requirement.contact || details.email.trim().length > 0 || details.phone.trim().length > 0);

/// Whether the token already supplied this row, which is why it renders as provided.
export const smileIDSampleRequirementSupplies = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
  field: UseSmileIDSampleUserField,
): boolean => {
  if (field === UseSmileIDSampleUserField.FirstName) return !requirement.firstName;
  if (field === UseSmileIDSampleUserField.LastName) return !requirement.lastName;
  // The rule is "one of", so a bound email leaves phone askable. Only the requirement itself lifts.
  return false;
};

/// A contact row stops saying "optional" the moment one of the two is actually required.
export const smileIDSampleRequirementLabel = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
  field: UseSmileIDSampleUserFieldSpec,
): string => {
  if (!requirement.contact) return field.label;
  if (field.id === UseSmileIDSampleUserField.Email) return 'Email';
  if (field.id === UseSmileIDSampleUserField.Phone) return 'Phone';
  return field.label;
};

const titlecase = (text: string): string => text.charAt(0).toUpperCase() + text.slice(1);

/// The sentence under the form, which has to name what is actually outstanding.
export const smileIDSampleRequirementPrompt = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
): string => {
  const outstanding: string[] = [];
  if (requirement.firstName) outstanding.push('first name');
  if (requirement.lastName) outstanding.push('last name');
  if (requirement.contact) outstanding.push('an email or phone number');
  if (outstanding.length === 0) return 'Tap any field to edit.';
  if (outstanding.length === 1) return `${titlecase(outstanding[0]!)} is required.`;
  return `Required: ${outstanding.join(', ')}.`;
};
