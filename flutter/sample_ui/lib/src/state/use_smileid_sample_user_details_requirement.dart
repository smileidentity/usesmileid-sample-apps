import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_product.dart';
import '../use_smileid_sample_strings.dart';
import 'use_smileid_sample_catalogue.dart';
import 'use_smileid_sample_profiles.dart';
import 'use_smileid_sample_token_decoder.dart';

/// What the consent form still has to collect, and which rows it leaves out: the product's `fields_to_collect`, or the token rule without one.
class UseSmileIDSampleUserDetailsRequirement {
  /// Everything required, which is what a launch with no token gets.
  const UseSmileIDSampleUserDetailsRequirement({
    this.firstName = true,
    this.lastName = true,
    this.contact = true,
    this.hidden = const <UseSmileIDSampleUserField>{},
  });

  /// Whether a given name is still needed.
  final bool firstName;

  /// Whether a family name is still needed.
  final bool lastName;

  /// Whether an email OR a phone is still needed; one of, never both.
  final bool contact;

  /// The rows the form does not draw: names the partner may leave out.
  final Set<UseSmileIDSampleUserField> hidden;

  /// Whether the form draws [field]'s row.
  bool shows(UseSmileIDSampleUserField field) => !hidden.contains(field);

  /// Nothing left to ask, so the form has no reason to appear.
  bool get isSatisfied => !firstName && !lastName && !contact;

  /// Whether the token supplied [field].
  bool supplies(UseSmileIDSampleUserField field) => switch (field) {
    UseSmileIDSampleUserField.firstName => !firstName && shows(field),
    UseSmileIDSampleUserField.lastName => !lastName && shows(field),
    // Contact is one of two, so neither row is supplied on its own.
    UseSmileIDSampleUserField.email || UseSmileIDSampleUserField.phone => false,
  };

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleUserDetailsRequirement &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.contact == contact &&
      setEquals(other.hidden, hidden);

  @override
  int get hashCode => Object.hash(
    firstName,
    lastName,
    contact,
    Object.hashAllUnordered(hidden),
  );

  /// Whether [details] satisfies what is still outstanding; the API judges each value's format.
  bool isSatisfiedBy(UseSmileIDSampleUserDetails details) =>
      (!firstName || details.firstName.trim().isNotEmpty) &&
      (!lastName || details.lastName.trim().isNotEmpty) &&
      (!contact ||
          details.email.trim().isNotEmpty ||
          details.phone.trim().isNotEmpty);

  /// The row's label, which gains "(optional)" only once a token has covered contact.
  String labelFor(
    UseSmileIDSampleUserField field,
    UseSmileIDSampleStrings strings,
  ) => contact && !field.isRequired
      ? field.title(strings)
      : field.label(strings);

  /// What this requirement still asks for; the SCREEN decides when nothing is outstanding.
  String prompt(UseSmileIDSampleStrings strings) {
    final List<String> outstanding = <String>[
      if (firstName) strings.userRequirementFirstName,
      if (lastName) strings.userRequirementLastName,
      if (contact) strings.userRequirementContact,
    ];
    if (outstanding.isEmpty) {
      return strings.userDetailsEditHint;
    }
    final String sentence = outstanding.length == 1
        ? strings.userRequirementOne(field: outstanding.single)
        : strings.userRequirementMany(
            fields: outstanding.join(strings.userRequirementSeparator),
          );
    return '${sentence[0].toUpperCase()}${sentence.substring(1)}';
  }
}

/// The requirement a token leaves behind.
UseSmileIDSampleUserDetailsRequirement useSmileIDSampleUserDetailsRequirement(
  UseSmileIDSampleTokenBindings? bindings,
) => UseSmileIDSampleUserDetailsRequirement(
  firstName: bindings?.givenNames != true,
  lastName: bindings?.lastName != true,
  contact: !(bindings?.email == true || bindings?.phoneNumber == true),
);

/// The token rule, less any name neither [product]'s `fields_to_collect` nor an ID type it offers requires (spec/user-details-fields.json).
UseSmileIDSampleUserDetailsRequirement
useSmileIDSampleUserDetailsRequirementFor(
  UseSmileIDSampleTokenBindings? bindings,
  UseSmileIDSampleProduct? product,
  Map<String, List<UseSmileIDSampleApiField>>? fieldsToCollect, [
  UseSmileIDSampleIdTypeFields? idTypeFields,
]) {
  final UseSmileIDSampleUserDetailsRequirement token =
      useSmileIDSampleUserDetailsRequirement(bindings);
  final String? key = product?.fieldsToCollectKey;
  final List<UseSmileIDSampleApiField>? fields = key == null
      ? null
      : fieldsToCollect?[key];
  if (product == null || key == null || fields == null) {
    return token;
  }
  final Iterable<List<UseSmileIDSampleApiField>> offered = product.readsIdTypes
      ? (idTypeFields?[key]?.values ??
                const <Map<String, List<UseSmileIDSampleApiField>>>[])
            .expand(
              (Map<String, List<UseSmileIDSampleApiField>> it) => it.values,
            )
      : const <List<UseSmileIDSampleApiField>>[];
  bool leftOut(String name, {required bool asked}) =>
      asked &&
      !fields.requires(name) &&
      !offered.any((List<UseSmileIDSampleApiField> it) => it.requires(name));
  final Set<UseSmileIDSampleUserField> hidden = <UseSmileIDSampleUserField>{
    if (leftOut('given_names', asked: token.firstName))
      UseSmileIDSampleUserField.firstName,
    if (leftOut('last_name', asked: token.lastName))
      UseSmileIDSampleUserField.lastName,
  };
  return UseSmileIDSampleUserDetailsRequirement(
    firstName:
        token.firstName &&
        !hidden.contains(UseSmileIDSampleUserField.firstName),
    lastName:
        token.lastName && !hidden.contains(UseSmileIDSampleUserField.lastName),
    contact: token.contact,
    hidden: hidden,
  );
}

/// Whether a field list asks for a name.
extension UseSmileIDSampleApiFieldsRequire on List<UseSmileIDSampleApiField> {
  /// Whether this list names [name] with `required: true`.
  bool requires(String name) => any(
    (UseSmileIDSampleApiField it) => it.name == name && it.required == true,
  );
}

/// The picked ID type's entry in `products`.
extension UseSmileIDSampleIdTypeEntry on UseSmileIDSampleIdTypeFields? {
  /// The picked ID type's fields, or null for a product that reads none or a pair with no entry.
  List<UseSmileIDSampleApiField>? entryFor(
    UseSmileIDSampleProduct? product,
    String? country,
    String? idType,
  ) {
    final String? key = product?.fieldsToCollectKey;
    if (product == null || !product.readsIdTypes || key == null) {
      return null;
    }
    return this?[key]?[country]?[idType];
  }
}

/// The product's key in `fields_to_collect`.
extension UseSmileIDSampleFieldsToCollectKey on UseSmileIDSampleProduct {
  /// Whether this product asks for names before its ID type is picked, so each ID type's entry in `products` counts.
  bool get readsIdTypes =>
      this == UseSmileIDSampleProduct.biometricKyc ||
      this == UseSmileIDSampleProduct.enhancedKyc;

  /// Null for the SmartSelfie products, which have none.
  String? get fieldsToCollectKey => switch (this) {
    UseSmileIDSampleProduct.smartSelfieEnrollment ||
    UseSmileIDSampleProduct.smartSelfieAuth => null,
    UseSmileIDSampleProduct.biometricKyc => 'biometric_kyc',
    UseSmileIDSampleProduct.enhancedKyc => 'enhanced_kyc',
    UseSmileIDSampleProduct.documentVerification => 'doc_verification',
    UseSmileIDSampleProduct.enhancedDocumentVerification =>
      'enhanced_document_verification',
    UseSmileIDSampleProduct.residencyDocumentVerification =>
      'residency_document_verification',
  };
}

/// A row the form hides submits nothing.
extension UseSmileIDSampleHiddenNames on UseSmileIDSampleUserDetails {
  /// These details with every name [requirement] does not show, or the picked ID type's [entry] does not require, left blank.
  UseSmileIDSampleUserDetails withoutHiddenNames(
    UseSmileIDSampleUserDetailsRequirement requirement, {
    List<UseSmileIDSampleApiField>? entry,
  }) {
    bool sends(UseSmileIDSampleUserField field, String name) =>
        requirement.shows(field) && (entry?.requires(name) ?? true);
    return UseSmileIDSampleUserDetails(
      firstName: sends(UseSmileIDSampleUserField.firstName, 'given_names')
          ? firstName
          : '',
      lastName: sends(UseSmileIDSampleUserField.lastName, 'last_name')
          ? lastName
          : '',
      email: email,
      phone: phone,
    );
  }
}

/// Mirrors the SDK's internal `bindsRequiredUserDetails`.
extension UseSmileIDSampleRequiredUserDetails on UseSmileIDSampleTokenBindings {
  /// Whether the token binds enough for the SDK to stop requiring `userDetails`.
  bool get bindsRequiredUserDetails =>
      useSmileIDSampleUserDetailsRequirement(this).isSatisfied;
}
