import 'package:flutter/material.dart';

import '../tokens/smile_product_hues.dart';

/// The design's Type/Label applied to a base style, for every all-caps label, badge and count.
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
