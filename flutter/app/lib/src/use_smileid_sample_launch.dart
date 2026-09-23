import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:sample_ui/sample_ui.dart';

import 'use_smileid_sample_routes.dart';

/// The link the platform launched this process at, or '/' when it was launched from the icon.
class UseSmileIDSampleLaunch {
  /// Takes the platform's raw route, which on Android is the launching intent's data.
  UseSmileIDSampleLaunch(String platformRoute)
    : _uri = Uri.tryParse(platformRoute) ?? Uri(path: platformRoute);

  final Uri _uri;

  /// Where the router should open, with the scheme and host folded back into the path.
  String get location {
    final String path = _uri.hasAuthority
        ? '/${_uri.authority}${_uri.path}'
        : _uri.path;
    final String trimmed = path.length > 1 && path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    return trimmed.isEmpty || trimmed == '/'
        ? UseSmileIDSampleRoutes.products
        : trimmed;
  }

  /// The arguments the link carried, defaulted where it carried none.
  UseSmileIDSampleLaunchArgs get args =>
      UseSmileIDSampleLaunchArgs.fromUri(_uri);
}

/// Everything a launch does to the stores before the first frame.
Future<void> useSmileIDSampleApplyLaunch(
  UseSmileIDSampleLaunchArgs args,
  UseSmileIDSampleJobsRepository jobs, {
  DateTime? now,
}) async {
  if (args.seedJobs) {
    await jobs.seedFixtures((now ?? DateTime.now()).millisecondsSinceEpoch);
  }
}

/// How long after the first frame a route push still counts as the link the process launched at.
const Duration useSmileIDSampleColdLinkWindow = Duration(seconds: 2);

/// Takes iOS's cold link, which the scene lifecycle pushes after the first frame instead of launching at.
class UseSmileIDSampleColdLink with WidgetsBindingObserver {
  /// [onLink] runs before the router sees the push, so a seed lands before the screen reads it.
  UseSmileIDSampleColdLink({
    required this.onLink,
    this.window = useSmileIDSampleColdLinkWindow,
  });

  /// Applies the link's arguments.
  final Future<void> Function(Uri link) onLink;

  /// How long after the first frame the push may arrive.
  final Duration window;

  bool _open = false;
  Timer? _timer;

  /// Waits for the first push, and stops at the first touch or [window] after the first frame.
  void listen() {
    _open = true;
    WidgetsBinding.instance.addObserver(this);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_open) {
        _timer ??= Timer(window, close);
      }
    });
  }

  /// Stops listening, after which every push is a warm link that never re-seeds.
  void close() {
    if (!_open) {
      return;
    }
    _open = false;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) {
      close();
    }
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (_open) {
      close();
      await onLink(routeInformation.uri);
    }
    // Never handled here: the router still navigates to the link.
    return false;
  }
}
