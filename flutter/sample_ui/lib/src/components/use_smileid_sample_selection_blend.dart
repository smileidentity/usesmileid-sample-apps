import 'package:flutter/widgets.dart';

import '../tokens/smile_tokens.dart';

/// Eases a picked state from 0 to 1 over duration-fast, instantly when the platform asks for reduced motion.
class UseSmileIDSampleSelectionBlend extends StatelessWidget {
  /// Builds with how far [selected] has eased in.
  const UseSmileIDSampleSelectionBlend({
    required this.selected,
    required this.builder,
    super.key,
  });

  /// Whether the control is picked.
  final bool selected;

  /// Draws the control at [picked], 0 unpicked to 1 picked.
  final Widget Function(BuildContext context, double picked) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: selected ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : SmileMotion.durationFast,
    builder: (BuildContext context, double picked, Widget? _) =>
        builder(context, picked),
  );
}
