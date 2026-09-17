import 'package:flutter/material.dart';

import '../tokens/smile_product_hues.dart';

/// The design's Type/Label applied to a base style, for every all-caps label, badge and count.
///
/// Flutter's `height` is a RATIO of the font size where Compose's `lineHeight` is absolute, so
/// raising the size from 10 to 11 would stretch the line box unless the ratio is recomputed.
TextStyle useSmileIDSampleLabelStyle(TextStyle base) {
  final double? size = base.fontSize;
  final double? ratio = base.height;
  return base.copyWith(
    fontSize: smileLabelSize,
    letterSpacing: smileLabelTracking,
    height: size == null || ratio == null
        ? ratio
        : size * ratio / smileLabelSize,
  );
}
