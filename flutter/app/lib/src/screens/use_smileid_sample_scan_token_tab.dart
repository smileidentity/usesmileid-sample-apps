import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../flow/use_smileid_sample_flow_tokens.dart';
import '../scan/use_smileid_sample_qr_scanner.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_routes.dart';

/// The token-scanning route.
class UseSmileIDSampleScanTokenTab extends ConsumerStatefulWidget {
  /// No route arguments: a pending run lives on app state.
  const UseSmileIDSampleScanTokenTab({super.key});

  @override
  ConsumerState<UseSmileIDSampleScanTokenTab> createState() =>
      _UseSmileIDSampleScanTokenTabState();
}

class _UseSmileIDSampleScanTokenTabState
    extends ConsumerState<UseSmileIDSampleScanTokenTab> {
  /// The run this visit was sent to resume.
  late final UseSmileIDSampleRunIntent? _resuming;

  @override
  void initState() {
    super.initState();
    _resuming = ref.read(useSmileIDSampleInterruptedRunProvider);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(useSmileIDSampleInterruptedRunProvider.notifier)
          .release(_resuming),
    );
  }

  bool _torchOn = false;

  /// Guards a second link from a double tap.
  bool _linking = false;

  void _back() =>
      useSmileIDSampleBack(context, UseSmileIDSampleRoutes.products);

  Future<void> _link(UseSmileIDSampleTokenSession session) async {
    if (_linking) {
      return;
    }
    _linking = true;
    final GoRouter router = GoRouter.of(context);
    await ref.read(useSmileIDSampleSessionProvider.notifier).link(session);
    final UseSmileIDSampleRunIntent? resuming = _resuming;
    // An expired relink cannot start the run.
    if (resuming == null ||
        session.hasExpired(DateTime.now().millisecondsSinceEpoch)) {
      if (mounted) {
        _back();
      }
      return;
    }
    if (!mounted) {
      return;
    }
    router.go(UseSmileIDSampleRoutes.sdkFlow(resuming.productId));
  }

  void _simulate(
    UseSmileIDSampleSimulatedSpan span,
    UseSmileIDSampleSimulatedBindings bindings,
    UseSmileIDSampleEnvironment environment,
  ) {
    final String minted = UseSmileIDSampleFlowTokens.session(
      span: span,
      bindings: bindings,
      environment: environment,
      nowMillis: DateTime.now().millisecondsSinceEpoch,
    );
    final UseSmileIDSampleTokenSession? session =
        UseSmileIDSampleTokenDecoder.session(minted);
    if (session != null) {
      unawaited(_link(session));
    }
  }

  Future<String?> _paste() async =>
      (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) {
      if (!didPop) {
        _back();
      }
    },
    child: Scaffold(
      backgroundColor: UseSmileIDSampleTheme.colorsOf(context).background,
      // Top only: the sheet insets its own bottom.
      body: SafeArea(
        bottom: false,
        child: UseSmileIDSampleTextMetrics(
          child: UseSmileIDSampleScanTokenScreen(
            reason: _resuming == null
                ? null
                : UseSmileIDSampleScanReason.sessionEnded,
            onBack: _back,
            onLink: (UseSmileIDSampleTokenSession session) =>
                unawaited(_link(session)),
            onSimulate: _simulate,
            onPaste: _paste,
            torchOn: _torchOn,
            onTorchToggle: () => setState(() => _torchOn = !_torchOn),
            viewfinder:
                (
                  BuildContext context, {
                  required bool enabled,
                  required ValueChanged<String> onCandidate,
                }) => UseSmileIDSampleQrScanner(
                  onCode: onCandidate,
                  torchOn: _torchOn,
                  enabled: enabled,
                ),
          ),
        ),
      ),
    ),
  );
}
