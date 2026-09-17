import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import 'state/use_smileid_sample_providers.dart';
import 'use_smileid_sample_routes.dart';

/// The app: the shared theme, and the router that hosts every route the journey adds.
class UseSmileIDSampleApp extends ConsumerStatefulWidget {
  /// Takes nothing; the shell owns the router and the theme selection.
  const UseSmileIDSampleApp({super.key});

  @override
  ConsumerState<UseSmileIDSampleApp> createState() =>
      _UseSmileIDSampleAppState();
}

class _UseSmileIDSampleAppState extends ConsumerState<UseSmileIDSampleApp> {
  // Built once: a router rebuilt on every frame loses its own navigation state.
  late final GoRouter _router = useSmileIDSampleRouter();

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
