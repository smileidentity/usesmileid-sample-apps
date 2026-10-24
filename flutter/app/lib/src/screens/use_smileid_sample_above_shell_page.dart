import 'package:flutter/material.dart';
import 'package:sample_ui/sample_ui.dart';

/// The chrome a step above the shell brings itself: page colour and safe area; back is njia's.
class UseSmileIDSampleAboveShellPage extends StatelessWidget {
  /// [child] on the page.
  const UseSmileIDSampleAboveShellPage({required this.child, super.key});

  /// The screen.
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UseSmileIDSampleTheme.colorsOf(context).background,
    body: SafeArea(child: UseSmileIDSampleTextMetrics(child: child)),
  );
}
