import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keys both system bars to the Dark mode switch, which overrides the device's appearance as the theme does.
class UseSmileIDSampleSystemBars extends StatelessWidget {
  /// Wraps [child], which is every route the router hosts.
  const UseSmileIDSampleSystemBars({
    required this.darkMode,
    required this.child,
    super.key,
  });

  /// The app's own switch, never the platform brightness.
  final bool darkMode;

  /// The router's output.
  final Widget child;

  /// Transparent bars with icons that contrast with the page; a route drawing its own region wins.
  static SystemUiOverlayStyle styleFor({required bool darkMode}) {
    // Built whole rather than from the `dark` preset, which pairs dark status icons with a black navigation bar.
    final Brightness icons = darkMode ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: darkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      // Keeps Android's own scrim behind three-button navigation, as enableEdgeToEdge does.
      systemNavigationBarContrastEnforced: true,
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: styleFor(darkMode: darkMode),
    child: child,
  );
}
