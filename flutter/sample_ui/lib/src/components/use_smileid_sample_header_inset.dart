import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../tokens/smile_tokens.dart';

/// The gap a header keeps below the status bar under a top camera cutout, which the bar ends flush with where an iPhone's safe area leaves room.
double useSmileIDSampleHeaderTopGap(BuildContext context) =>
    defaultTargetPlatform == TargetPlatform.android &&
        UseSmileIDSampleTopCutout.of(context) &&
        !UseSmileIDSampleLargeScreenFramed.of(context)
    ? SmileDimens.spacingSm
    : 0;

/// Whether a host's large-screen frame draws these screens, keeping the status bar outside it.
class UseSmileIDSampleLargeScreenFramed extends InheritedWidget {
  /// Wraps [child], the screens the host may frame.
  const UseSmileIDSampleLargeScreenFramed({
    required this.framed,
    required super.child,
    super.key,
  });

  /// True while the frame is drawn.
  final bool framed;

  /// Whether [context] is inside a drawn large-screen frame.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            UseSmileIDSampleLargeScreenFramed
          >()
          ?.framed ??
      false;

  @override
  bool updateShouldNotify(UseSmileIDSampleLargeScreenFramed oldWidget) =>
      framed != oldWidget.framed;
}

/// Whether the screens sit under a top camera cutout with the status bar shown, as the host reads it natively.
class UseSmileIDSampleTopCutout extends InheritedWidget {
  /// Wraps [child] with what the host read.
  const UseSmileIDSampleTopCutout({
    required this.present,
    required super.child,
    super.key,
  });

  /// True under a top cutout with the status bar shown.
  final bool present;

  /// What the nearest host read, or false without one.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<UseSmileIDSampleTopCutout>()
          ?.present ??
      false;

  @override
  bool updateShouldNotify(UseSmileIDSampleTopCutout oldWidget) =>
      present != oldWidget.present;
}
