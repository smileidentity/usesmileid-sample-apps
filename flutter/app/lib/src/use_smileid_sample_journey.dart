import 'package:sample_ui/sample_ui.dart';

import 'use_smileid_sample_routes.dart';

/// Where a product tap goes first, and where each form goes next.
abstract final class UseSmileIDSampleJourney {
  /// The first step for [product]: every product collects user details before its flow.
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
