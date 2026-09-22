import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keys both system bars to the Dark mode switch rather than the device.
class UseSmileIDSampleSystemBars extends StatelessWidget {
  /// Wraps the router's output.
  const UseSmileIDSampleSystemBars({
    required this.darkMode,
    required this.child,
    super.key,
  });

  /// The Dark mode switch.
  final bool darkMode;

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
    value: styleFor(darkMode: darkMode),
    child: child,
  );
}
