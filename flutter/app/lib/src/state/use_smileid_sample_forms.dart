import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

/// What the two pre-flow forms have collected, held above them so a back and forward keeps it.
class UseSmileIDSampleForms {
  /// Everything empty, which is what a cold start shows even for a profile with saved defaults.
  const UseSmileIDSampleForms({
    this.userDetails = const UseSmileIDSampleUserDetails(),
    this.idDetails = const UseSmileIDSampleIdDetails(),
    this.rememberDetails = false,
  });

  /// The consent form's four fields.
  final UseSmileIDSampleUserDetails userDetails;

  /// The ID form's three.
  final UseSmileIDSampleIdDetails idDetails;

  /// The remember switch, which persists nothing today.
  final bool rememberDetails;

  /// A copy with one part replaced.
  UseSmileIDSampleForms copyWith({
    UseSmileIDSampleUserDetails? userDetails,
    UseSmileIDSampleIdDetails? idDetails,
    bool? rememberDetails,
  }) => UseSmileIDSampleForms(
    userDetails: userDetails ?? this.userDetails,
    idDetails: idDetails ?? this.idDetails,
    rememberDetails: rememberDetails ?? this.rememberDetails,
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

  /// Toggles the remember switch.
  void setRemember(bool remember) =>
      state = state.copyWith(rememberDetails: remember);

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
