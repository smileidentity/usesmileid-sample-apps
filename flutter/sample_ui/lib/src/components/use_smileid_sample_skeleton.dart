import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../tokens/smile_tokens.dart';

/// Skeleton rows show only after [delay], so a fast answer never flashes, then for at least [minimumShown].
class UseSmileIDSampleSkeletonGate extends ChangeNotifier {
  /// The shipped timing; tests pass their own clock through [now].
  UseSmileIDSampleSkeletonGate({
    this.delay = const Duration(milliseconds: 300),
    this.minimumShown = const Duration(milliseconds: 400),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// How long a load runs before rows appear.
  final Duration delay;

  /// How long rows stay once shown.
  final Duration minimumShown;

  final DateTime Function() _now;
  Timer? _pending;
  DateTime? _shownAt;
  bool _visible = false;

  /// Whether the rows draw.
  bool get visible => _visible;

  /// Called whenever the list's loading state may have changed.
  void loading(bool isLoading) {
    _pending?.cancel();
    if (isLoading) {
      if (_visible) {
        return;
      }
      _pending = Timer(delay, () {
        _shownAt = _now();
        _set(true);
      });
    } else if (_visible) {
      final Duration left = minimumShown - _now().difference(_shownAt!);
      if (left > Duration.zero) {
        _pending = Timer(left, () => _set(false));
      } else {
        _set(false);
      }
    }
  }

  void _set(bool visible) {
    _visible = visible;
    notifyListeners();
  }

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }
}

/// Six OptionRow-shaped placeholders; one element to accessibility, announcing [announcement].
class UseSmileIDSampleSkeletonRows extends StatefulWidget {
  /// [leadingCircle] draws where a country row's flag goes.
  const UseSmileIDSampleSkeletonRows({
    required this.announcement,
    this.leadingCircle = false,
    this.testId,
    super.key,
  });

  /// What a screen reader hears, e.g. "Loading countries".
  final String announcement;

  /// Whether each row leads with a flag-sized circle.
  final bool leadingCircle;

  /// The `sample_*` id the sheet supplies.
  final String? testId;

  @override
  State<UseSmileIDSampleSkeletonRows> createState() =>
      _UseSmileIDSampleSkeletonRowsState();
}

class _UseSmileIDSampleSkeletonRowsState
    extends State<UseSmileIDSampleSkeletonRows>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: SmileMotion.skeletonDuration,
  );

  /// Six widths so the rows do not read as a table.
  static const List<double> _widths = <double>[
    0.72,
    0.48,
    0.64,
    0.56,
    0.80,
    0.40,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: widget.testId,
      label: widget.announcement,
      container: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext context, Widget? child) {
          final Color fill = Color.lerp(
            colors.skeleton,
            colors.skeletonHighlight,
            _pulse.value,
          )!;
          return Column(
            children: <Widget>[
              for (final double width in _widths)
                SizedBox(
                  height: SmileDimens.sizeControlMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SmileDimens.spacingSm,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (widget.leadingCircle) ...<Widget>[
                          Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              color: fill,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: SmileDimens.spacingSm),
                        ],
                        Expanded(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: width,
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: fill,
                                borderRadius: BorderRadius.circular(
                                  SmileDimens.radiusField,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
