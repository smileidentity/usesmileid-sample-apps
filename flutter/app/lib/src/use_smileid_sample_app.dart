import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import 'use_smileid_sample_routes.dart';

/// The app: the shared theme, and the router that hosts every route the journey adds.
class UseSmileIDSampleApp extends StatefulWidget {
  /// Takes nothing; the shell owns the router and the theme selection.
  const UseSmileIDSampleApp({super.key});

  @override
  State<UseSmileIDSampleApp> createState() => _UseSmileIDSampleAppState();
}

class _UseSmileIDSampleAppState extends State<UseSmileIDSampleApp> {
  // Built once: a router rebuilt on every frame loses its own navigation state.
  late final GoRouter _router = useSmileIDSampleRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'UseSmileID Sample',
    debugShowCheckedModeBanner: false,
    theme: UseSmileIDSampleTheme.light(),
    darkTheme: UseSmileIDSampleTheme.dark(),
    // The Settings switch replaces this once it persists; until then the host's own mode wins,
    // which is what the SDK follows too.
    themeMode: ThemeMode.system,
    routerConfig: _router,
  );
}
