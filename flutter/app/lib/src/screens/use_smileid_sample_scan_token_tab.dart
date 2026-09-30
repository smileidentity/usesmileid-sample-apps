import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../flow/use_smileid_sample_flow_tokens.dart';
import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../scan/use_smileid_sample_qr_scanner.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_journey.dart';
import '../use_smileid_sample_routes.dart';
import 'use_smileid_sample_settings_tab.dart';

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

  /// Whether the session had ended when this visit began, which decides the caption.
  late final bool _arrivedEnded;

  /// False until the push lands, so a second tap on the nav bar's Token button cannot land on Simulate.
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _resuming = ref.read(useSmileIDSampleInterruptedRunProvider);
    _arrivedEnded = useSmileIDSampleSessionEnded(
      ref.read(useSmileIDSampleSessionProvider),
      ref.read(useSmileIDSampleWallClockProvider)(),
    );
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
    final UseSmileIDSampleProduct? product = UseSmileIDSampleProduct.values
        .where((UseSmileIDSampleProduct it) => it.id == resuming.productId)
        .firstOrNull;
    if (resuming.resumeAt == UseSmileIDSampleResumePoint.firstStep &&
        product != null) {
      unawaited(
        router.pushReplacement(
          UseSmileIDSampleJourney.firstStepFor(
            product,
            useSmileIDSampleLiveBindings(ref),
          ),
        ),
      );
      return;
    }
    router.go(UseSmileIDSampleRoutes.sdkFlow(resuming.productId));
  }

  /// The route's own enter animation, watched once for its end.
  Animation<double>? _entering;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settled || _entering != null) {
      return;
    }
    final Animation<double>? animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _settled = true;
      return;
    }
    _entering = animation..addStatusListener(_onRouteAnimation);
  }

  void _onRouteAnimation(AnimationStatus status) {
    if (status.isCompleted && mounted) {
      _entering?.removeStatusListener(_onRouteAnimation);
      setState(() => _settled = true);
    }
  }

  @override
  void dispose() {
    _entering?.removeStatusListener(_onRouteAnimation);
    super.dispose();
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
                : _arrivedEnded
                ? UseSmileIDSampleScanReason.sessionEnded
                : UseSmileIDSampleScanReason.sessionNeeded,
            acceptsTaps: _settled,
            // External, not in-app: the Portal sign-in lives in the browser.
            onOpenPortal: () => unawaited(
              useSmileIDSampleOpenLink(
                UseSmileIDSampleScanTokenScreen.portalUrl,
                inApp: false,
              ),
            ),
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
