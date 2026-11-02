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
    final MediaQueryData media = MediaQuery.of(context);
    // The system bars' padding, which a keyboard doesn't change, so the frame keeps still as one opens.
    final EdgeInsets padding = media.viewPadding;
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
        return ColoredBox(
          color: frame != null ? background : Colors.transparent,
          child: Padding(
            padding: frame != null ? padding : EdgeInsets.zero,
            child: Center(
              child: SizedBox(
                width: frame?.width ?? double.infinity,
                height: frame?.height ?? double.infinity,
                child: ClipRect(
                  clipBehavior: frame != null ? Clip.hardEdge : Clip.none,
                  child: frame == null
                      ? MediaQuery(data: media, child: child)
                      : MediaQuery(
                          data: _insideFrame(media, window, padding, frame),
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

  /// What the screens inside a [frame] centred in [window] see: no safe area padding, which stays outside it, and only the part of a keyboard that covers the frame.
  static MediaQueryData _insideFrame(
    MediaQueryData media,
    Size window,
    EdgeInsets padding,
    Size frame,
  ) {
    final double frameBottom =
        padding.top +
        (window.height - padding.vertical - frame.height) / 2 +
        frame.height;
    final double keyboard = math.max(
      0,
      media.viewInsets.bottom - (window.height - frameBottom),
    );
    return media
        .removePadding(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
        )
        .removeViewPadding(
          removeLeft: true,
          removeTop: true,
          removeRight: true,
          removeBottom: true,
        )
        .copyWith(viewInsets: EdgeInsets.only(bottom: keyboard));
  }
}
