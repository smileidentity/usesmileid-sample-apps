import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import 'state/use_smileid_sample_providers.dart';
import 'state/use_smileid_sample_session_providers.dart';
import 'use_smileid_sample_routes.dart';
import 'use_smileid_sample_system_bars.dart';

/// The app: the shared theme, and the router that hosts every route the journey adds.
class UseSmileIDSampleApp extends ConsumerStatefulWidget {
  /// [initialLocation] is where the launching link pointed, already folded into a path.
  const UseSmileIDSampleApp({this.initialLocation, super.key});

  /// Where to open, or null to open at the start destination.
  final String? initialLocation;

  @override
  ConsumerState<UseSmileIDSampleApp> createState() =>
      _UseSmileIDSampleAppState();
}

class _UseSmileIDSampleAppState extends ConsumerState<UseSmileIDSampleApp> {
  // Built once: a router rebuilt on every frame loses its own navigation state.
  late final GoRouter _router = useSmileIDSampleRouter(
    initialLocation: widget.initialLocation,
  );

  /// Re-reads the deadline on resume, since no timer fires while the device sleeps.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(
        ref.read(useSmileIDSampleSessionProvider.notifier).checkDeadline(),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool darkMode = ref.watch(
      useSmileIDSampleSettingsProvider.select(
        (UseSmileIDSampleSettings settings) => settings.darkMode,
      ),
    );
    return MaterialApp.router(
      title: 'UseSmileID Sample',
      debugShowCheckedModeBanner: false,
      theme: UseSmileIDSampleTheme.light(),
      darkTheme: UseSmileIDSampleTheme.dark(),
      // Pinned both ways: the switch overrides the device.
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      builder: (BuildContext context, Widget? child) =>
          UseSmileIDSampleSystemBars(
            darkMode: darkMode,
            child: child ?? const SizedBox.shrink(),
          ),
    );
  }
}
