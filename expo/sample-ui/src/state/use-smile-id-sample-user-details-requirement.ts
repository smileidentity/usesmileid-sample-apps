import type { UseSmileIDSampleFieldsToCollect } from './use-smile-id-sample-catalogue';
import { smileIDSampleDetailsContactProblem } from './use-smile-id-sample-contact-rules';
import type { UseSmileIDSampleTokenBindings } from './use-smile-id-sample-token-decoder';
import type { UseSmileIDSampleUserDetails } from './use-smile-id-sample-profiles';
import type { UseSmileIDSampleProduct } from '../model/use-smile-id-sample-product';
import { UseSmileIDSampleUserField, type UseSmileIDSampleUserFieldSpec } from '../model/use-smile-id-sample-user-fields';
import { type UseSmileIDSampleStrings } from '../use-smile-id-sample-strings';

export type { UseSmileIDSampleTokenBindings };

/// What the form must still collect, and which rows it leaves out: the product's `fields_to_collect`, or the token rule without one.
export type UseSmileIDSampleUserDetailsRequirement = {
  readonly firstName: boolean;
  readonly lastName: boolean;
  /// One of email or phone, which is why neither row is individually supplied.
  readonly contact: boolean;
  /// The rows the form does not draw: names the partner may leave out.
  readonly hidden?: readonly UseSmileIDSampleUserField[];
};

/// Whether the form draws `field`'s row.
export const smileIDSampleRequirementShows = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
  field: UseSmileIDSampleUserField,
): boolean => !(requirement.hidden ?? []).includes(field);

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

/// The product's key in `fields_to_collect`; null for the SmartSelfie products, which have none.
export const smileIDSampleFieldsToCollectKey = (product: UseSmileIDSampleProduct): string | null =>
  ({
    biometricKyc: 'biometric_kyc',
    enhancedKyc: 'enhanced_kyc',
    documentVerification: 'doc_verification',
    enhancedDocumentVerification: 'enhanced_document_verification',
    residencyDocumentVerification: 'residency_document_verification',
  })[product.id] ?? null;

/// The token rule, less any name `product`'s `fields_to_collect` lets the partner leave out (spec/user-details-fields.json).
export const smileIDSampleRequirementFor = (
  bindings: UseSmileIDSampleTokenBindings | null | undefined,
  product: UseSmileIDSampleProduct | null | undefined,
  fieldsToCollect: UseSmileIDSampleFieldsToCollect | null | undefined,
): UseSmileIDSampleUserDetailsRequirement => {
  const token = smileIDSampleRequirementFrom(bindings);
  const key = product ? smileIDSampleFieldsToCollectKey(product) : null;
  const fields = key === null ? undefined : fieldsToCollect?.[key];
  if (fields === undefined) return token;
  const leftOut = (name: string, asked: boolean): boolean =>
    asked && fields.some((field) => field.name === name && field.required !== true);
  const hidden = [
    ...(leftOut('given_names', token.firstName) ? [UseSmileIDSampleUserField.FirstName] : []),
    ...(leftOut('last_name', token.lastName) ? [UseSmileIDSampleUserField.LastName] : []),
  ];
  return {
    firstName: token.firstName && !hidden.includes(UseSmileIDSampleUserField.FirstName),
    lastName: token.lastName && !hidden.includes(UseSmileIDSampleUserField.LastName),
    contact: token.contact,
    hidden,
  };
};

/// `details` with every name `requirement` does not show left blank, since a row the form hides submits nothing.
export const smileIDSampleDetailsWithoutHiddenNames = (
  details: UseSmileIDSampleUserDetails,
  requirement: UseSmileIDSampleUserDetailsRequirement,
): UseSmileIDSampleUserDetails => ({
  ...details,
  firstName: smileIDSampleRequirementShows(requirement, UseSmileIDSampleUserField.FirstName) ? details.firstName : '',
  lastName: smileIDSampleRequirementShows(requirement, UseSmileIDSampleUserField.LastName) ? details.lastName : '',
});

/// Nothing left to ask, so the form has no reason to appear.
export const smileIDSampleRequirementSatisfied = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
): boolean => !requirement.firstName && !requirement.lastName && !requirement.contact;

/// No relevant binding at all, the one case the SDK's own validator can still decide.
export const smileIDSampleRequirementBindsNothing = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
): boolean => requirement.firstName && requirement.lastName && requirement.contact;

/// Whether the form has collected what the requirement still asks of it, in a form the server accepts.
export const smileIDSampleDetailsSatisfy = (
  details: UseSmileIDSampleUserDetails,
  requirement: UseSmileIDSampleUserDetailsRequirement,
): boolean =>
  (!requirement.firstName || details.firstName.trim().length > 0) &&
  (!requirement.lastName || details.lastName.trim().length > 0) &&
  (!requirement.contact || details.email.trim().length > 0 || details.phone.trim().length > 0) &&
  smileIDSampleDetailsContactProblem(details) === null;

/// Whether the token already supplied this row, which is why it renders as provided.
export const smileIDSampleRequirementSupplies = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
  field: UseSmileIDSampleUserField,
): boolean => {
  if (field === UseSmileIDSampleUserField.FirstName) {
    return !requirement.firstName && smileIDSampleRequirementShows(requirement, field);
  }
  if (field === UseSmileIDSampleUserField.LastName) {
    return !requirement.lastName && smileIDSampleRequirementShows(requirement, field);
  }
  // The rule is "one of", so a bound email leaves phone askable. Only the requirement itself lifts.
  return false;
};

/// A contact row stops saying "optional" the moment one of the two is actually required.
export const smileIDSampleRequirementLabel = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
  field: UseSmileIDSampleUserFieldSpec,
  strings: UseSmileIDSampleStrings,
): string => (requirement.contact && !field.required ? field.title(strings) : field.label(strings));

const titlecase = (text: string): string => text.charAt(0).toUpperCase() + text.slice(1);

/// The sentence under the form, which has to name what is actually outstanding.
export const smileIDSampleRequirementPrompt = (
  requirement: UseSmileIDSampleUserDetailsRequirement,
  strings: UseSmileIDSampleStrings,
): string => {
  const outstanding: string[] = [];
  if (requirement.firstName) outstanding.push(strings.userRequirementFirstName);
  if (requirement.lastName) outstanding.push(strings.userRequirementLastName);
  if (requirement.contact) outstanding.push(strings.userRequirementContact);
  if (outstanding.length === 0) return strings.userDetailsEditHint;
  if (outstanding.length === 1) return strings.userRequirementOne({ field: titlecase(outstanding[0]!) });
  return strings.userRequirementMany({ fields: outstanding.join(strings.userRequirementSeparator) });
};
