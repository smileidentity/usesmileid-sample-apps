import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../use_smileid_sample_component_gallery.dart';
import '../use_smileid_sample_shell.dart';

/// The app's router: platform links reach the shell, and the system back reaches the page njia's host sits on.
RouterConfig<Uri> useSmileIDSampleRouterConfig({Uri? launchLink}) =>
    RouterConfig<Uri>(
      routeInformationProvider: PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(
          uri: launchLink ?? Uri(path: '/'),
        ),
      ),
      routeInformationParser: const _UseSmileIDSampleLinkParser(),
      routerDelegate: _UseSmileIDSampleRouterDelegate(),
      backButtonDispatcher: RootBackButtonDispatcher(),
    );

/// A link as the platform sent it: the shell reads it, so nothing is parsed here.
class _UseSmileIDSampleLinkParser extends RouteInformationParser<Uri> {
  const _UseSmileIDSampleLinkParser();

  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture<Uri>(routeInformation.uri);
}

/// The shell's page, with the dev gallery over it when a link opens it.
class _UseSmileIDSampleRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final StreamController<Uri> _links = StreamController<Uri>.broadcast();

  Uri? _launch;

  bool _gallery = false;

  static const ValueKey<String> _shellKey = ValueKey<String>('shell');

  static const ValueKey<String> _galleryKey = ValueKey<String>('gallery');

  @override
  Future<void> setInitialRoutePath(Uri configuration) {
    _launch = configuration;
    return SynchronousFuture<void>(null);
  }

  @override
  Future<void> setNewRoutePath(Uri configuration) {
    _links.add(configuration);
    return SynchronousFuture<void>(null);
  }

  void _openGallery() {
    _gallery = true;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    pages: <Page<void>>[
      MaterialPage<void>(
        key: _shellKey,
        child: UseSmileIDSampleShell(
          launchLink: _launch,
          links: _links.stream,
          onGallery: _openGallery,
        ),
      ),
      if (_gallery)
        const MaterialPage<void>(
          key: _galleryKey,
          child: UseSmileIDSampleComponentGallery(),
        ),
    ],
    onDidRemovePage: (Page<Object?> page) {
      if (page.key == _galleryKey) {
        _gallery = false;
        notifyListeners();
      }
    },
  );

  @override
  void dispose() {
    unawaited(_links.close());
    super.dispose();
  }
}
