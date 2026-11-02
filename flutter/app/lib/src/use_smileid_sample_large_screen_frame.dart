import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sample_ui/sample_ui.dart';

/// The largest phone's frame the app's own screens draw in on a large screen, from `spec/large-screen-frame.json`.
abstract final class UseSmileIDSampleLargeScreen {
  /// The shorter side a large screen starts at.
  static const double minSide = 600;

  /// The iPhone 18 Pro Max's screen, the SDK's own large-screen frame on iOS.
  static const Size iosFrame = Size(440, 956);

  /// The Galaxy S26 Ultra's screen at its default display size, the SDK's own large-screen frame on Android.
  static const Size androidFrame = Size(384, 832);

  /// The frame on [platform]: the iPhone's on iOS, the Galaxy's elsewhere.
  static Size frameOn(TargetPlatform platform) =>
      platform == TargetPlatform.iOS ? iosFrame : androidFrame;

  /// The app's size in a [window] whose safe area is [safeArea]: the frame, each side the safe area's where shorter, on a large screen; null on a phone.
  static Size? frameSize(Size window, Size safeArea, TargetPlatform platform) {
    if (math.min(window.width, window.height) < minSide) {
      return null;
    }
    final Size frame = frameOn(platform);
    return Size(
      math.min(math.max(safeArea.width, 0), frame.width),
      math.min(math.max(safeArea.height, 0), frame.height),
    );
  }
}

/// Draws [child] on a large screen as the largest phone shows it, centred on the screen background; a phone, or [framed] false, fills the window.
class UseSmileIDSampleLargeScreenFrame extends StatelessWidget {
  /// A frame around [child], which steps aside while [framed] is false.
  const UseSmileIDSampleLargeScreenFrame({
    super.key,
    required this.framed,
    required this.child,
  });

  /// Whether the frame draws: false while the full-screen SDK run, which frames itself, is on top.
  final bool framed;

  /// The app's screens.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final Color background = UseSmileIDSampleTheme.colorsOf(context).background;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size window = constraints.biggest;
        final Size? frame = framed
            ? UseSmileIDSampleLargeScreen.frameSize(
                window,
                Size(
                  window.width - padding.horizontal,
                  window.height - padding.vertical,
                ),
                defaultTargetPlatform,
              )
            : null;
        final bool large = frame != null;
        return ColoredBox(
          color: large ? background : Colors.transparent,
          child: Padding(
            padding: large ? padding : EdgeInsets.zero,
            child: Center(
              child: SizedBox(
                width: frame?.width ?? double.infinity,
                height: frame?.height ?? double.infinity,
                child: ClipRect(
                  clipBehavior: large ? Clip.hardEdge : Clip.none,
                  child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: large,
                    removeTop: large,
                    removeRight: large,
                    removeBottom: large,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
