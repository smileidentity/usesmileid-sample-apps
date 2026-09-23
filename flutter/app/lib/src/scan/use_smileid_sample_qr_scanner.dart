import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The shell's QR camera, released when it leaves the tree.
class UseSmileIDSampleQrScanner extends StatefulWidget {
  /// [enabled] is false while the screen shows a result.
  const UseSmileIDSampleQrScanner({
    required this.onCode,
    required this.torchOn,
    this.enabled = true,
    super.key,
  });

  /// A decoded QR payload, reported once per distinct value.
  final ValueChanged<String> onCode;

  /// Whether the torch is lit.
  final bool torchOn;

  /// Whether a code may be reported now.
  final bool enabled;

  @override
  State<UseSmileIDSampleQrScanner> createState() =>
      _UseSmileIDSampleQrScannerState();
}

class _UseSmileIDSampleQrScannerState extends State<UseSmileIDSampleQrScanner> {
  late final MobileScannerController _controller = MobileScannerController(
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    // Android defaults to 640x480, too coarse for a dense token QR.
    cameraResolution: _analysisSize,
    torchEnabled: widget.torchOn,
  );

  /// The last value reported, cleared on retry.
  String? _lastReported;

  @override
  void didUpdateWidget(UseSmileIDSampleQrScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _lastReported = null;
    }
    if (widget.torchOn != oldWidget.torchOn) {
      unawaited(_toggleTorch());
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } on Object {
      // A lens with no torch.
    }
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _detect(BarcodeCapture capture) {
    if (!widget.enabled) {
      return;
    }
    for (final Barcode barcode in capture.barcodes) {
      final String? value = barcode.rawValue;
      if (value != null && value.isNotEmpty && value != _lastReported) {
        _lastReported = value;
        widget.onCode(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => MobileScanner(
    controller: _controller,
    onDetect: _detect,
    errorBuilder: (BuildContext context, MobileScannerException error) =>
        const SizedBox.shrink(),
  );
}

/// The analysis resolution, pinned.
const Size _analysisSize = Size(1920, 1080);
