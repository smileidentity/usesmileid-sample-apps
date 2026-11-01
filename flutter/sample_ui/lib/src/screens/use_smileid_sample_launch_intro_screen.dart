import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/use_smileid_sample_logo.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../use_smileid_sample_strings_scope.dart';

/// The cold-start intro: "SmileID" unrolls out of the logo's lock, which shuts and opens again on the way; a tap skips to [onFinished].
class UseSmileIDSampleLaunchIntroScreen extends StatefulWidget {
  /// [onFinished] runs once, when the intro ends or is tapped away.
  const UseSmileIDSampleLaunchIntroScreen({
    required this.onFinished,
    super.key,
  });

  /// Hands the window back to the app.
  final VoidCallback onFinished;

  @override
  State<UseSmileIDSampleLaunchIntroScreen> createState() =>
      _UseSmileIDSampleLaunchIntroScreenState();
}

class _UseSmileIDSampleLaunchIntroScreenState
    extends State<UseSmileIDSampleLaunchIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: UseSmileIDSampleLaunchIntroTimeline.duration,
  );
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _progress.forward().whenComplete(_finish);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  /// Once only, whether the timeline ran out or a tap came first.
  void _finish() {
    if (_finished || !mounted) {
      return;
    }
    _finished = true;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _finish,
    child: UseSmileIDSampleLaunchIntroFrame(progress: _progress),
  );
}

/// One frame of the intro, always on the dark scheme; [progress] repaints without rebuilding.
class UseSmileIDSampleLaunchIntroFrame extends StatelessWidget {
  /// Draws the intro wherever [progress] stands.
  const UseSmileIDSampleLaunchIntroFrame({required this.progress, super.key});

  /// From 0, an empty screen, to 1, the logo at rest.
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleColorSchemes.dark;
    return Semantics(
      label: context.strings.launchIntroLabel,
      image: true,
      child: ColoredBox(
        color: colors.background,
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _LaunchIntroPainter(
              progress: progress,
              ink: colors.textTitle,
              accent: colors.decorative.orange,
            ),
          ),
        ),
      ),
    );
  }
}

/// Where every part of the logo is at one instant; [shackleLock] runs from 0, the logo's own open shackle, to 1, seated on the body.
@immutable
class UseSmileIDSampleLaunchIntroPose {
  /// One instant of the intro.
  const UseSmileIDSampleLaunchIntroPose({
    required this.markAlpha,
    required this.markScale,
    required this.shackleLock,
    required this.shackleLift,
    required this.clickSquash,
    required this.ringProgress,
    required this.wordmarkReveal,
  });

  /// The logo as the brand draws it, which is where every intro ends.
  static const UseSmileIDSampleLaunchIntroPose rest =
      UseSmileIDSampleLaunchIntroPose(
        markAlpha: 1,
        markScale: 1,
        shackleLock: 0,
        shackleLift: 0,
        clickSquash: 0,
        ringProgress: 1,
        wordmarkReveal: 1,
      );

  /// The lock's opacity.
  final double markAlpha;

  /// The lock's size against its own, about its centre.
  final double markScale;

  /// How far the shackle has moved onto the body.
  final double shackleLock;

  /// How high the shackle is off the body, in logo units.
  final double shackleLift;

  /// How hard the body is squashed by a landing.
  final double clickSquash;

  /// The click's ring, from 0 to gone at 1.
  final double ringProgress;

  /// How much of the name has unrolled.
  final double wordmarkReveal;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleLaunchIntroPose &&
      other.markAlpha == markAlpha &&
      other.markScale == markScale &&
      other.shackleLock == shackleLock &&
      other.shackleLift == shackleLift &&
      other.clickSquash == clickSquash &&
      other.ringProgress == ringProgress &&
      other.wordmarkReveal == wordmarkReveal;

  @override
  int get hashCode => Object.hash(
    markAlpha,
    markScale,
    shackleLock,
    shackleLift,
    clickSquash,
    ringProgress,
    wordmarkReveal,
  );

  @override
  String toString() =>
      'UseSmileIDSampleLaunchIntroPose(markAlpha: $markAlpha, markScale: $markScale, '
      'shackleLock: $shackleLock, shackleLift: $shackleLift, clickSquash: $clickSquash, '
      'ringProgress: $ringProgress, wordmarkReveal: $wordmarkReveal)';
}

/// The intro's choreography in milliseconds, as a pure function of progress so goldens can stop it on any frame.
abstract final class UseSmileIDSampleLaunchIntroTimeline {
  /// The whole intro.
  static const Duration duration = Duration(milliseconds: _durationMillis);

  /// The logo drawn in full size, its shackle still in the brand's open position.
  static const double appeared = 500 / _durationMillis;

  /// The shackle seated on the body, with the name part-way out.
  static const double locked = 1150 / _durationMillis;

  static const int _durationMillis = 2800;
  static const double _markStartScale = 0.85;
  static const double _hopHeight = 1.6;
  static const double _unlockClickStrength = 0.6;
  static const Curve _fastOutSlowIn = Cubic(0.4, 0, 0.2, 1);
  static const Curve _linearOutSlowIn = Cubic(0, 0, 0.2, 1);

  /// The pose at [progress], clamped to the timeline.
  static UseSmileIDSampleLaunchIntroPose pose(double progress) {
    final double ms = progress.clamp(0.0, 1.0) * _durationMillis;
    final double lock = _phase(ms, 600, 1000, _fastOutSlowIn);
    final double unlock = _phase(ms, 1300, 1700, _fastOutSlowIn);
    return UseSmileIDSampleLaunchIntroPose(
      markAlpha: _phase(ms, 0, 350, _linearOutSlowIn),
      markScale: _lerp(_markStartScale, 1, _phase(ms, 0, 450, _fastOutSlowIn)),
      shackleLock: lock * (1 - unlock),
      shackleLift: _hopHeight * (_arc(lock) + _arc(unlock)),
      clickSquash:
          _bump(_phase(ms, 1000, 1250, Curves.linear)) +
          _unlockClickStrength * _bump(_phase(ms, 1700, 1950, Curves.linear)),
      ringProgress: _phase(ms, 1000, 1500, _linearOutSlowIn),
      wordmarkReveal: _phase(ms, 350, 1600, _linearOutSlowIn),
    );
  }

  static double _phase(double ms, double start, double end, Curve curve) =>
      curve.transform(((ms - start) / (end - start)).clamp(0.0, 1.0));

  /// A hop's height along its flight: zero on the ground at both ends, never below it.
  static double _arc(double flight) =>
      flight > 0 && flight < 1 ? math.sin(flight * math.pi) : 0;

  /// A landing's squash, decaying to nothing so the body settles back to its own shape.
  static double _bump(double time) => (1 - time) * _arc(time);
}

double _lerp(double start, double stop, double fraction) =>
    start + (stop - start) * fraction;

/// Draws one pose in the logo's own viewport units.
class _LaunchIntroPainter extends CustomPainter {
  _LaunchIntroPainter({
    required this.progress,
    required this.ink,
    required this.accent,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color ink;
  final Color accent;

  static const double _logoWidthFraction = 0.62;
  static const double _squashY = 0.14;
  static const double _squashX = 0.07;
  static const double _ringStartRadius = 4;
  static const double _ringEndRadius = 9;
  static const double _ringStroke = 0.16;
  static const double _ringAlpha = 0.45;
  static const double _wordmarkSlide = 2;
  static const double _clipBleed = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final UseSmileIDSampleLaunchIntroPose pose =
        UseSmileIDSampleLaunchIntroTimeline.pose(progress.value);
    const Rect bounds = UseSmileIDSampleLogo.bounds;
    const Rect mark = UseSmileIDSampleLogo.markBounds;
    final double logoScale = size.width * _logoWidthFraction / bounds.width;
    // Centres what is visible so far, so the name pushes the lock aside as it unrolls.
    final double visibleRight = _lerp(
      mark.right,
      bounds.right,
      pose.wordmarkReveal,
    );
    final Offset focus = Offset(
      (mark.left + visibleRight) / 2,
      bounds.center.dy,
    );

    canvas
      ..save()
      ..translate(
        size.width / 2 - focus.dx * logoScale,
        size.height / 2 - focus.dy * logoScale,
      )
      ..scale(logoScale);

    canvas.save();
    _scaleAbout(canvas, pose.markScale, pose.markScale, mark.center);
    _drawLock(canvas, pose);
    canvas.restore();

    if (pose.wordmarkReveal > 0) {
      const Rect words = UseSmileIDSampleLogo.wordmarkBounds;
      final double start = words.left - _clipBleed;
      canvas
        ..save()
        ..clipRect(
          Rect.fromLTRB(
            start,
            bounds.top - _clipBleed,
            _lerp(start, words.right + _clipBleed, pose.wordmarkReveal),
            bounds.bottom + _clipBleed,
          ),
        )
        ..translate(-_wordmarkSlide * (1 - pose.wordmarkReveal), 0)
        ..drawPath(UseSmileIDSampleLogo.wordmark, Paint()..color = ink)
        ..restore();
    }
    canvas.restore();
  }

  void _drawLock(Canvas canvas, UseSmileIDSampleLaunchIntroPose pose) {
    if (pose.ringProgress > 0 && pose.ringProgress < 1) {
      canvas.drawCircle(
        Offset(
          UseSmileIDSampleLogo.bodyBase.dx,
          UseSmileIDSampleLogo.markBounds.center.dy,
        ),
        _lerp(_ringStartRadius, _ringEndRadius, pose.ringProgress),
        Paint()
          ..color = accent.withValues(
            alpha: (1 - pose.ringProgress) * _ringAlpha,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringStroke,
      );
    }
    final double bodyScaleY = 1 - _squashY * pose.clickSquash;
    final double bodyScaleX = 1 + _squashX * pose.clickSquash;
    canvas.save();
    _scaleAbout(canvas, bodyScaleX, bodyScaleY, UseSmileIDSampleLogo.bodyBase);
    canvas.drawPath(
      UseSmileIDSampleLogo.body,
      Paint()..color = ink.withValues(alpha: pose.markAlpha),
    );
    canvas.restore();

    // The shackle rides the body's top edge, so it sinks with the squash instead of floating above it.
    final double seatDrop =
        (UseSmileIDSampleLogo.bodyBase.dy - UseSmileIDSampleLogo.bodyTop) *
        (1 - bodyScaleY);
    canvas
      ..save()
      ..translate(
        UseSmileIDSampleLogo.lockedShackleShift * pose.shackleLock,
        seatDrop - pose.shackleLift,
      )
      ..drawPath(
        UseSmileIDSampleLogo.shackle,
        Paint()..color = accent.withValues(alpha: pose.markAlpha),
      )
      ..restore();
  }

  /// Scales about [pivot] rather than the origin, as the other platforms' canvases do.
  static void _scaleAbout(Canvas canvas, double x, double y, Offset pivot) {
    canvas
      ..translate(pivot.dx, pivot.dy)
      ..scale(x, y)
      ..translate(-pivot.dx, -pivot.dy);
  }

  @override
  bool shouldRepaint(_LaunchIntroPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ink != ink ||
      oldDelegate.accent != accent;
}
