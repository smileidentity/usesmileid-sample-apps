import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import 'state/use_smileid_sample_providers.dart';
import 'use_smileid_sample_routes.dart';

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
      // The switch is an override, not a preference for the system: off means follow the device,
      // which is what the SDK does, and on means dark whatever the device says.
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.system,
      routerConfig: _router,
    );
  }
}
