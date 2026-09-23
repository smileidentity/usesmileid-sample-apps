import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// The shell's QR camera; it releases the camera when it leaves the tree, so the SDK gets it back.
///
/// A denied permission renders nothing: the sheet's manual entry still links a token.
class UseSmileIDSampleQrScanner extends StatefulWidget {
  /// [enabled] is false while the screen shows what it just found, so frames are not read behind it.
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
    // Android's default is 640x480, at which a v3 token QR decodes only once it overflows the reticle.
    cameraResolution: _analysisSize,
    torchEnabled: widget.torchOn,
  );

  /// Keyed on the last value reported, so a retry re-reads the same QR without re-reporting it mid-result.
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
      // A lens with no torch; the control has nothing to switch.
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

/// Pinned, in the 16:9 the native app negotiates, and flipped by the plugin in portrait.
const Size _analysisSize = Size(1920, 1080);
