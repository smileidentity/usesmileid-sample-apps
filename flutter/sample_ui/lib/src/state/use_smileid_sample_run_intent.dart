import 'package:flutter/foundation.dart';

import '../model/use_smileid_sample_result.dart';

/// Where a relinked run picks up: its first step, or straight back into the SDK.
enum UseSmileIDSampleResumePoint {
  /// Sent from a product tap: the new token's bindings decide which forms come first.
  firstStep,

  /// Sent from the SDK-entry gate: the forms are already filled.
  flow,
}

/// A run a gate sent to the scanner, carrying the presentation it was launched in.
@immutable
class UseSmileIDSampleRunIntent {
  /// [productId] and [route] are the run's.
  const UseSmileIDSampleRunIntent({
    required this.productId,
    required this.route,
    this.resumeAt = UseSmileIDSampleResumePoint.flow,
  });

  /// The product the run was for.
  final String productId;

  /// Where it was presented.
  final UseSmileIDSampleFlowRoute route;

  /// Where the run picks up once a session is linked.
  final UseSmileIDSampleResumePoint resumeAt;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleRunIntent &&
      other.productId == productId &&
      other.route == route &&
      other.resumeAt == resumeAt;

  @override
  int get hashCode => Object.hash(productId, route, resumeAt);
}
