import 'package:flutter/services.dart';

/// The scale a product card draws at: smaller while held, unless it is disabled or motion is reduced.
double useSmileIDSamplePressScale({
  required bool pressed,
  required bool enabled,
  required bool reduceMotion,
}) => pressed && enabled && !reduceMotion ? _pressedScale : 1;

/// The tick a toggle plays on [platform]: iOS's light impact, which UISwitch plays, and Android's selection click.
Future<void> useSmileIDSampleToggleTick(TargetPlatform platform) =>
    platform == TargetPlatform.iOS
    ? HapticFeedback.lightImpact()
    : HapticFeedback.selectionClick();

const double _pressedScale = 0.97;
