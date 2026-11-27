/// The scale a product card draws at: smaller while held, unless it is disabled or motion is reduced.
double useSmileIDSamplePressScale({
  required bool pressed,
  required bool enabled,
  required bool reduceMotion,
}) => pressed && enabled && !reduceMotion ? _pressedScale : 1;

const double _pressedScale = 0.97;
