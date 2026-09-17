import 'package:sample_ui/sample_ui.dart';

import 'use_smileid_sample_routes.dart';

/// Where a product tap goes first, and where each form goes next.
///
/// One place rather than one per screen: the order is the journey's, and a second copy is how two
/// entry points come to disagree about which form a product needs.
abstract final class UseSmileIDSampleJourney {
  /// The first step for [product]: every product collects user details before its flow.
  ///
  /// A token that already binds those details skips this step on the twin; no token session exists
  /// here yet, so nothing skips it.
  static String firstStepFor(UseSmileIDSampleProduct product) =>
      UseSmileIDSampleRoutes.consentDetailsForm(product.id);

  /// What follows the user-details form: the ID form, or the flow itself.
  static String afterUserDetails(UseSmileIDSampleProduct product) =>
      product.needsIdDetails
      ? UseSmileIDSampleRoutes.idDetailsForm(product.id)
      : UseSmileIDSampleRoutes.sdkFlow(product.id);

  /// What follows the ID-details form.
  static String afterIdDetails(UseSmileIDSampleProduct product) =>
      UseSmileIDSampleRoutes.sdkFlow(product.id);
}
