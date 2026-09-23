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

/// The token-scanning route: links a session, and resumes the run the expiry gate sent here.
class UseSmileIDSampleScanTokenTab extends ConsumerStatefulWidget {
  /// Takes nothing from the route: continuation state lives on app state, never in a path.
  const UseSmileIDSampleScanTokenTab({super.key});

  @override
  ConsumerState<UseSmileIDSampleScanTokenTab> createState() =>
      _UseSmileIDSampleScanTokenTabState();
}

class _UseSmileIDSampleScanTokenTabState
    extends ConsumerState<UseSmileIDSampleScanTokenTab> {
  /// Owned by this visit, so leaving by any route drops it and a later scan cannot resurrect it.
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

  /// Guards a second link: two quick taps mint two tokens and must not start two runs.
  bool _linking = false;

  void _back() =>
      useSmileIDSampleBack(context, UseSmileIDSampleRoutes.products);

  Future<void> _link(UseSmileIDSampleTokenSession session) async {
    if (_linking) {
      return;
    }
    _linking = true;
    // Read before the await: the notifier outlives this route, the context may not.
    final GoRouter router = GoRouter.of(context);
    await ref.read(useSmileIDSampleSessionProvider.notifier).link(session);
    final UseSmileIDSampleRunIntent? resuming = _resuming;
    // An already-expired relink cannot start the run, so it leaves rather than freezing on "linked".
    if (resuming == null ||
        session.hasExpired(DateTime.now().millisecondsSinceEpoch)) {
      if (mounted) {
        _back();
      }
      return;
    }
    // Left during the write: the person chose not to resume.
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
    // A fixture that no longer decodes is a defect, never something to paper over with a made-up session.
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
      // Top only: the sheet insets its own bottom, so a second inset here would lift it twice.
      body: SafeArea(
        bottom: false,
        child: UseSmileIDSampleTextMetrics(
          child: UseSmileIDSampleScanTokenScreen(
            // Why the screen opened, which belongs to the screen the redirect arrives at.
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
            // The camera lives in the shell: `sample_ui` runs under hosts that carry none.
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
