import 'package:flutter/material.dart';
import 'package:sample_ui/sample_ui.dart';

/// The chrome a route above the shell brings itself: page colour, safe area, and where back goes.
class UseSmileIDSampleAboveShellPage extends StatelessWidget {
  /// [onBack] is where the app bar's back and the system's both land.
  const UseSmileIDSampleAboveShellPage({
    required this.onBack,
    required this.child,
    super.key,
  });

  /// Where back lands, from the app bar and from the system alike.
  final VoidCallback onBack;

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    // Entered with `go`, so this is the root stack's only page: a plain pop would leave the app.
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) {
      if (!didPop) {
        onBack();
      }
    },
    child: Scaffold(
      backgroundColor: UseSmileIDSampleTheme.colorsOf(context).background,
      body: SafeArea(child: UseSmileIDSampleTextMetrics(child: child)),
    ),
  );
}
