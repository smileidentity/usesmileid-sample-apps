import 'package:flutter/widgets.dart';

import '../tokens/smile_tokens.dart';

const Duration _riseDuration = Duration(milliseconds: 220);
const double _fadeShareOfRise = 160 / 220;

/// Content that rises its own height into place, fading in, when it first appears; the toast's own entrance.
class UseSmileIDSampleRiseIn extends StatefulWidget {
  /// Rises [child] in.
  const UseSmileIDSampleRiseIn({required this.child, super.key});

  /// What rises.
  final Widget child;

  @override
  State<UseSmileIDSampleRiseIn> createState() => _UseSmileIDSampleRiseInState();
}

class _UseSmileIDSampleRiseInState extends State<UseSmileIDSampleRiseIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: _riseDuration,
  );
  late final Animation<Offset> _position = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _rise, curve: Curves.fastOutSlowIn));
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _rise,
    curve: const Interval(0, _fadeShareOfRise, curve: Curves.fastOutSlowIn),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _rise.value = 1;
    } else {
      _rise.forward();
    }
  }

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SlideTransition(
    position: _position,
    child: FadeTransition(opacity: _opacity, child: widget.child),
  );
}

/// Content that fades in over duration-fast when it first appears, as a list does when it replaces its loading state.
class UseSmileIDSampleFadeIn extends StatefulWidget {
  /// Fades [child] in.
  const UseSmileIDSampleFadeIn({required this.child, super.key});

  /// What fades.
  final Widget child;

  @override
  State<UseSmileIDSampleFadeIn> createState() => _UseSmileIDSampleFadeInState();
}

class _UseSmileIDSampleFadeInState extends State<UseSmileIDSampleFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: SmileMotion.durationFast,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = 1;
    } else {
      _fade.forward();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: widget.child);
}
