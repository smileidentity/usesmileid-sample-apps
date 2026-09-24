import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

/// What the two pre-flow forms have collected, held above them so a back and forward keeps it.
class UseSmileIDSampleForms {
  /// Everything empty; a run fills the user details from its profile.
  const UseSmileIDSampleForms({
    this.userDetails = const UseSmileIDSampleUserDetails(),
    this.idDetails = const UseSmileIDSampleIdDetails(),
    this.saveToProfile = true,
    this.organisation = '',
  });

  /// The consent form's four fields.
  final UseSmileIDSampleUserDetails userDetails;

  /// The ID form's three.
  final UseSmileIDSampleIdDetails idDetails;

  /// Whether Continue keeps what was typed: into the active profile, or as a new one when there is none.
  final bool saveToProfile;

  /// The new profile's name, asked only while there is no profile.
  final String organisation;

  /// A copy with one part replaced.
  UseSmileIDSampleForms copyWith({
    UseSmileIDSampleUserDetails? userDetails,
    UseSmileIDSampleIdDetails? idDetails,
    bool? saveToProfile,
    String? organisation,
  }) => UseSmileIDSampleForms(
    userDetails: userDetails ?? this.userDetails,
    idDetails: idDetails ?? this.idDetails,
    saveToProfile: saveToProfile ?? this.saveToProfile,
    organisation: organisation ?? this.organisation,
  );
}

/// The forms' live state, which sign-out clears.
final NotifierProvider<UseSmileIDSampleFormsNotifier, UseSmileIDSampleForms>
useSmileIDSampleFormsProvider =
    NotifierProvider<UseSmileIDSampleFormsNotifier, UseSmileIDSampleForms>(
      UseSmileIDSampleFormsNotifier.new,
    );

/// Holds what the forms have collected.
class UseSmileIDSampleFormsNotifier extends Notifier<UseSmileIDSampleForms> {
  @override
  UseSmileIDSampleForms build() => const UseSmileIDSampleForms();

  /// Sets one user-details field.
  void setUserField(UseSmileIDSampleUserField field, String value) => state =
      state.copyWith(userDetails: field.apply(state.userDetails, value));

  /// Toggles the save switch.
  void setSaveToProfile(bool save) =>
      state = state.copyWith(saveToProfile: save);

  /// Types the new profile's organisation.
  void setOrganisation(String organisation) =>
      state = state.copyWith(organisation: organisation);

  /// A run starts from the profile it runs as; whatever was typed for another is dropped.
  void fillFrom(UseSmileIDSampleProfile profile) => state = state.copyWith(
    userDetails: profile.defaults,
    saveToProfile: true,
    organisation: '',
  );

  /// Chooses a country, which CLEARS the ID type: the old country's types may not apply.
  void setCountry(UseSmileIDSampleCountry country) =>
      state = state.copyWith(idDetails: state.idDetails.withCountry(country));

  /// Chooses an ID type.
  void setIdType(UseSmileIDSampleIdType idType) =>
      state = state.copyWith(idDetails: state.idDetails.withIdType(idType));

  /// Types the ID number.
  void setIdNumber(String idNumber) =>
      state = state.copyWith(idDetails: state.idDetails.withIdNumber(idNumber));

  /// Forgets everything, which is what signing out does.
  void clear() => state = const UseSmileIDSampleForms();
}
