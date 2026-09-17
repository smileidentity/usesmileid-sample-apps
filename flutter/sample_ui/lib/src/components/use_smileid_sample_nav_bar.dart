import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_icons.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_icon.dart';

/// The three destinations the nav bar switches between. The token affordance is not one of them.
enum UseSmileIDSampleNavItem {
  /// The products grid.
  products(
    UseSmileIDSampleTestIds.navProducts,
    'Products',
    SmileIcons.products,
  ),

  /// The verifications list.
  verifications(
    UseSmileIDSampleTestIds.navVerifications,
    'Verifications',
    SmileIcons.verifications,
  ),

  /// Settings.
  settings(
    UseSmileIDSampleTestIds.navSettings,
    'Settings',
    SmileIcons.settings,
  );

  const UseSmileIDSampleNavItem(this.testId, this.label, this.icon);

  /// The `sample_*` id a flow taps.
  final String testId;

  /// The tab's label, beneath its icon.
  final String label;

  /// The tab's mark, which the design supplies.
  final String icon;
}

/// A floating pill of three tabs, plus a detached token button that navigates rather than
/// switching tab.
///
/// The bar FLOATS over the content: the list scrolls underneath it and the background stays
/// continuous, so a screen's own trailing spacer is what lets its last row scroll clear.
class UseSmileIDSampleNavBar extends StatelessWidget {
  /// [sessionProgress] drives the ring, 1 fresh to 0 expired, from the deadline not an animation.
  const UseSmileIDSampleNavBar({
    required this.selected,
    required this.onSelect,
    required this.onTokenTap,
    this.sessionProgress,
    super.key,
  });

  /// Which tab is active.
  final UseSmileIDSampleNavItem selected;

  /// Switches tab.
  final ValueChanged<UseSmileIDSampleNavItem> onSelect;

  /// Opens the token screen, which is a push rather than a tab.
  final VoidCallback onTokenTap;

  /// The session's remaining fraction, absent when there is no session.
  final double? sessionProgress;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Padding(
      // Edge to edge, so without its own inset the bar sits under the system navigation bar.
      padding: EdgeInsets.only(
        left: SmileDimens.spacingMd,
        right: SmileDimens.spacingMd,
        top: SmileDimens.spacingSm,
        bottom:
            SmileDimens.spacingSm + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Material(
              // The pill has its own fill: the design recesses it below the page, which this
              // app's page colour cannot express without hiding the bar.
              color: colors.navBar,
              shape: const StadiumBorder(),
              elevation: _barElevation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SmileDimens.spacingXs,
                  vertical: SmileDimens.spacingXxs,
                ),
                child: Row(
                  children: <Widget>[
                    for (final UseSmileIDSampleNavItem item
                        in UseSmileIDSampleNavItem.values)
                      Expanded(
                        child: _NavBarTab(
                          item: item,
                          selected: item == selected,
                          onTap: () => onSelect(item),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: SmileDimens.spacingXs),
          _TokenAffordance(progress: sessionProgress, onTap: onTokenTap),
        ],
      ),
    );
  }
}

/// The countdown ring: green rather than primary, and driven by remaining time.
class UseSmileIDSampleTokenRing extends StatelessWidget {
  /// [progress] is 1 fresh to 0 expired; anything outside that is clamped rather than rejected.
  const UseSmileIDSampleTokenRing({
    required this.progress,
    this.size,
    super.key,
  });

  /// The session's remaining fraction.
  final double progress;

  /// The square the ring is drawn into.
  final double? size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size ?? _tokenSize),
    painter: _TokenRingPainter(progress: progress, inflate: 0),
  );
}

/// The ring is painted OUTSIDE the button's bounds rather than laid out around it: given its own
/// room in the layout it pushed the token button off a 393-wide screen.
class _TokenAffordance extends StatelessWidget {
  const _TokenAffordance({required this.progress, required this.onTap});

  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final Widget button = Material(
      color: colors.navBar,
      shape: const CircleBorder(),
      elevation: _barElevation,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          // A minimum, not a fixed box: a fixed 58 ellipsises "Token" at 2x.
          constraints: const BoxConstraints(
            minWidth: _tokenSize,
            minHeight: _tokenSize,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UseSmileIDSampleIcon(
                asset: SmileIcons.tokenScan,
                tint: colors.foreground,
                size: SmileDimens.sizeIconSm,
              ),
              const SizedBox(height: SmileDimens.spacingXxs),
              Text(
                'Token',
                style: UseSmileIDSampleType.textStyleOverline.copyWith(
                  fontSize: _tokenLabelSize,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      identifier: UseSmileIDSampleTestIds.navToken,
      button: true,
      child: progress == null
          ? button
          : CustomPaint(
              painter: _TokenRingPainter(
                progress: progress!,
                inflate: _ringBleed,
              ),
              child: button,
            ),
    );
  }
}

class _TokenRingPainter extends CustomPainter {
  const _TokenRingPainter({required this.progress, required this.inflate});

  final double progress;
  final double inflate;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringThickness
      ..strokeCap = StrokeCap.round;
    final double offset = _ringThickness / 2 - inflate;
    final double diameter = size.shortestSide - _ringThickness + inflate * 2;
    final Rect bounds = Rect.fromLTWH(offset, offset, diameter, diameter);

    canvas.drawArc(
      bounds,
      0,
      _fullTurn,
      false,
      stroke
        ..color = smileTokenRing.withValues(alpha: smileTokenRingTrackOpacity),
    );
    canvas.drawArc(
      bounds,
      _quarterTurnUp,
      _fullTurn * progress.clamp(0, 1),
      false,
      stroke..color = smileTokenRing,
    );
  }

  @override
  bool shouldRepaint(_TokenRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.inflate != inflate;
}

class _NavBarTab extends StatelessWidget {
  const _NavBarTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final UseSmileIDSampleNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // Unselected takes the warm Off_black, not muted text, which is what the frame draws.
    final Color tint = selected ? colors.primary : colors.foreground;
    return Semantics(
      identifier: item.testId,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.all(SmileDimens.spacingXs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UseSmileIDSampleIcon(
                asset: item.icon,
                tint: tint,
                size: _tabIconSize,
              ),
              const SizedBox(height: SmileDimens.spacingXxs),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: UseSmileIDSampleType.textStyleOverline.copyWith(
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A spacing token standing in for an elevation, because no token carries one — see the
/// `floatingElevation` delta. It matches the design's 8 y-offset, which is the reproducible half.
const double _barElevation = SmileDimens.space8;

/// How far the ring is pushed outside the button it circles.
const double _ringBleed = 5;

/// The ring's own stroke.
const double _ringThickness = 4;

/// The tab mark, read off the board rather than the icon scale.
const double _tabIconSize = 21;

/// The token button's minimum, which is NOT size.control-md's 44.
const double _tokenSize = 58;

/// The token label's run.
const double _tokenLabelSize = 8.5;

const double _fullTurn = 360 * math.pi / 180;
const double _quarterTurnUp = -90 * math.pi / 180;
