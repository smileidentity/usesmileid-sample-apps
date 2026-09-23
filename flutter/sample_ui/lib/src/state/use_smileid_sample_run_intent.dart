import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_result.dart';

/// A run the expiry gate sent away, carrying the presentation it was launched in.
@immutable
class UseSmileIDSampleRunIntent {
  /// [productId] and [route] are the run's.
  const UseSmileIDSampleRunIntent({
    required this.productId,
    required this.route,
  });

  /// The product the run was for.
  final String productId;

  /// Where it was presented.
  final UseSmileIDSampleFlowRoute route;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleRunIntent &&
      other.productId == productId &&
      other.route == route;

  @override
  int get hashCode => Object.hash(productId, route);
}
