import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

import 'catalogue/use_smileid_sample_catalogue_providers.dart';
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

class _UseSmileIDSampleAppState extends ConsumerState<UseSmileIDSampleApp>
    with WidgetsBindingObserver {
  // Built once: a router rebuilt on every frame loses its own navigation state.
  late final GoRouter _router = useSmileIDSampleRouter(
    initialLocation: widget.initialLocation,
  );

  /// Re-reads the deadline on resume, since no timer fires while the device sleeps.
  late final AppLifecycleListener _lifecycle;

  /// The device's languages, re-read when they change.
  List<String> _deviceLanguages = _readDeviceLanguages();

  static List<String> _readDeviceLanguages() => WidgetsBinding
      .instance
      .platformDispatcher
      .locales
      .map((Locale locale) => locale.toLanguageTag())
      .toList();

  @override
  void didChangeLocales(List<Locale>? locales) =>
      setState(() => _deviceLanguages = _readDeviceLanguages());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(
        ref.read(useSmileIDSampleSessionProvider.notifier).checkDeadline(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleAppearance appearance = ref.watch(
      useSmileIDSampleSettingsProvider.select(
        (UseSmileIDSampleSettings settings) => settings.appearance,
      ),
    );
    final UseSmileIDSampleLanguage choice = ref.watch(
      useSmileIDSampleSettingsProvider.select(
        (UseSmileIDSampleSettings settings) => settings.language,
      ),
    );
    final String? appLocale = ref
        .watch(useSmileIDSampleLaunchArgsProvider)
        .appLocale;
    final UseSmileIDSampleLanguage? pinned =
        (appLocale == null
            ? null
            : UseSmileIDSampleLanguage.shipped(appLocale)) ??
        (choice == UseSmileIDSampleLanguage.system ? null : choice);
    final UseSmileIDSampleLanguage shown =
        pinned ?? choice.resolved(_deviceLanguages);
    useSmileIDSampleCatalogueLanguage = pinned?.id;
    // The SDK reads this when a flow mounts.
    UseSmileIDLocalizations.localeResolver = (_) => Locale(shown.id);
    return MaterialApp.router(
      title: 'UseSmileID Sample',
      debugShowCheckedModeBanner: false,
      theme: UseSmileIDSampleTheme.light(),
      darkTheme: UseSmileIDSampleTheme.dark(),
      themeMode: switch (appearance) {
        UseSmileIDSampleAppearance.system => ThemeMode.system,
        UseSmileIDSampleAppearance.light => ThemeMode.light,
        UseSmileIDSampleAppearance.dark => ThemeMode.dark,
      },
      routerConfig: _router,
      locale: Locale(shown.id),
      supportedLocales: <Locale>[
        for (final UseSmileIDSampleLanguage language
            in UseSmileIDSampleLanguage.values)
          if (language != UseSmileIDSampleLanguage.system) Locale(language.id),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? child) =>
          UseSmileIDSampleStringsScope(
            language: shown,
            deviceLanguages: _deviceLanguages,
            child: Directionality(
              textDirection: shown.rightToLeft
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: UseSmileIDSampleSystemBars(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
    );
  }
}
