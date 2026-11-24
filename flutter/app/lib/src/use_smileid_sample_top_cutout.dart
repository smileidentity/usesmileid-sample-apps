import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sample_ui/sample_ui.dart';

/// The channel the Android activity answers on.
const MethodChannel useSmileIDSampleCutoutChannel = MethodChannel(
  'usesmileid_sample/cutout',
);

/// Whether the Android activity reads a top camera cutout under a shown status bar, or null off Android or when it cannot answer.
Future<bool?> useSmileIDSampleReadTopCutout() async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    return await useSmileIDSampleCutoutChannel.invokeMethod<bool>(
          'hasTopCutout',
        ) ??
        false;
  } on Exception {
    // No activity behind the call, as in a widget test, or a failed read.
    return null;
  }
}

/// Tells the shared screens whether they sit under a top camera cutout with the status bar shown, read natively as the Android and Expo apps read it, since some phones' engines report none.
class UseSmileIDSampleTopCutoutHost extends StatefulWidget {
  /// Wraps [child], the app, above any SafeArea that would hide the status bar inset, starting from [initial].
  const UseSmileIDSampleTopCutoutHost({
    required this.child,
    this.initial = false,
    super.key,
  });

  /// The app.
  final Widget child;

  /// The reading taken before launch, so the first frame needs no correction.
  final bool initial;

  @override
  State<UseSmileIDSampleTopCutoutHost> createState() =>
      _UseSmileIDSampleTopCutoutHostState();
}

class _UseSmileIDSampleTopCutoutHostState
    extends State<UseSmileIDSampleTopCutoutHost>
    with WidgetsBindingObserver {
  bool _native = false;
  int _request = 0;
  ({Size size, EdgeInsets viewPadding, EdgeInsets padding})? _metrics;

  @override
  void initState() {
    super.initState();
    _native = widget.initial;
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
    // By value: the engine's ViewPadding has no equality of its own.
    final ({Size size, EdgeInsets viewPadding, EdgeInsets padding}) metrics = (
      size: view.physicalSize,
      viewPadding: EdgeInsets.fromViewPadding(view.viewPadding, 1),
      padding: EdgeInsets.fromViewPadding(view.padding, 1),
    );
    if (metrics == _metrics) return;
    _metrics = metrics;
    _read();
  }

  Future<void> _read() async {
    final int request = ++_request;
    final bool? native = await useSmileIDSampleReadTopCutout();
    if (native != null && mounted && request == _request && native != _native) {
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
