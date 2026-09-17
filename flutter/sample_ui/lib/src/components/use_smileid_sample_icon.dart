import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../model/use_smileid_sample_product.dart';
import '../tokens/smile_icons.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';

/// The design set's icons, tinted at the call site so the vendored file keeps its own colour.
class UseSmileIDSampleIcon extends StatelessWidget {
  /// [asset] comes from [SmileIcons], which is generated, so a renamed icon fails to compile.
  const UseSmileIDSampleIcon({
    required this.asset,
    required this.tint,
    this.size = SmileDimens.sizeIconMd,
    super.key,
  });

  /// The vendored asset path.
  final String asset;

  /// The colour to draw it in.
  final Color tint;

  /// The square it is drawn into.
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    // Decorative: every call site pairs it with its own label.
    excludeFromSemantics: true,
  );
}

/// Which mark a product draws; the two document products share one, told apart by the hue.
String productIcon(UseSmileIDSampleProduct product) => switch (product) {
  UseSmileIDSampleProduct.smartSelfieEnrollment =>
    SmileIcons.smartSelfieEnrollment,
  UseSmileIDSampleProduct.smartSelfieAuth => SmileIcons.smartSelfieAuth,
  UseSmileIDSampleProduct.documentVerification =>
    SmileIcons.documentVerification,
  UseSmileIDSampleProduct.enhancedDocumentVerification =>
    SmileIcons.documentVerification,
  UseSmileIDSampleProduct.biometricKyc => SmileIcons.biometricKyc,
  UseSmileIDSampleProduct.enhancedKyc => SmileIcons.enhancedKyc,
};

/// A product's colouring, which lives in `spec/design-tokens.json` rather than the design system.
SmileProductHue productHue(UseSmileIDSampleProduct product) {
  final SmileProductHue? hue = smileProductHues[product.id];
  if (hue == null) {
    throw StateError(
      "no hue for product '${product.id}'; see spec/design-tokens.json → productHues",
    );
  }
  return hue;
}
