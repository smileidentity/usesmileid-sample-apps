import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keys both system bars to the theme the app renders, which a pinned appearance can set against the device.
class UseSmileIDSampleSystemBars extends StatelessWidget {
  /// Wraps the router's output; sits inside `MaterialApp.builder`, where the theme is already resolved.
  const UseSmileIDSampleSystemBars({required this.child, super.key});

  /// The router's output.
  final Widget child;

  /// Transparent bars whose icons contrast with the page.
  static SystemUiOverlayStyle styleFor({required bool darkMode}) {
    // Not the `dark` preset, which pairs dark icons with a black navigation bar.
    final Brightness icons = darkMode ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: darkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      // Keeps Android's scrim behind three-button navigation.
      systemNavigationBarContrastEnforced: true,
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: styleFor(darkMode: Theme.of(context).brightness == Brightness.dark),
    child: child,
  );
}
