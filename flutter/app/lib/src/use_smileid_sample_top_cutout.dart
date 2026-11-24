import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sample_ui/sample_ui.dart';

/// The channel the Android activity answers on.
const MethodChannel useSmileIDSampleCutoutChannel = MethodChannel(
  'usesmileid_sample/cutout',
);

/// Tells the shared screens whether they sit under a top camera cutout with the status bar shown, read natively as the Android and Expo apps read it, since some phones' engines report none.
class UseSmileIDSampleTopCutoutHost extends StatefulWidget {
  /// Wraps [child], the app, above any SafeArea that would hide the status bar inset.
  const UseSmileIDSampleTopCutoutHost({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  State<UseSmileIDSampleTopCutoutHost> createState() =>
      _UseSmileIDSampleTopCutoutHostState();
}

class _UseSmileIDSampleTopCutoutHostState
    extends State<UseSmileIDSampleTopCutoutHost>
    with WidgetsBindingObserver {
  bool _native = false;
  int _request = 0;
  ({Size size, ViewPadding viewPadding, ViewPadding padding})? _metrics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readIfMoved();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _readIfMoved();

  // A keyboard animates the metrics every frame and never moves the cutout, so only its changes are skipped.
  void _readIfMoved() {
    final FlutterView view = View.of(context);
    final ({Size size, ViewPadding viewPadding, ViewPadding padding}) metrics =
        (
          size: view.physicalSize,
          viewPadding: view.viewPadding,
          padding: view.padding,
        );
    if (metrics == _metrics) return;
    _metrics = metrics;
    _read();
  }

  Future<void> _read() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final int request = ++_request;
    final bool native;
    try {
      native =
          await useSmileIDSampleCutoutChannel.invokeMethod<bool>(
            'hasTopCutout',
          ) ??
          false;
    } on Exception {
      // No activity behind the host, as in a widget test, or a failed read: keep what was read before.
      return;
    }
    if (mounted && request == _request && native != _native) {
      setState(() => _native = native);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool statusBarShown = MediaQuery.viewPaddingOf(context).top > 0;
    return UseSmileIDSampleTopCutout(
      present:
          defaultTargetPlatform == TargetPlatform.android &&
          statusBarShown &&
          _native,
      child: widget.child,
    );
  }
}
