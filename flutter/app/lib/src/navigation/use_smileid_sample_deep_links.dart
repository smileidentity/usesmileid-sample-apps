import 'package:flutter/foundation.dart';
import 'package:sample_ui/sample_ui.dart';

/// A deep link as the graph reads it: the [path] it opens and, for the run, the [route] it asked for.
@immutable
final class UseSmileIDSampleLink {
  /// A link to the graph step at [path].
  const UseSmileIDSampleLink(this.path, {this.route});

  /// The graph link, without a leading slash.
  final String path;

  /// The presentation a run link asked for; null for any other link.
  final UseSmileIDSampleFlowRoute? route;
}

/// The app's links: the paths are `spec/njia-graph.json`'s, shared by the four apps; the scheme is the app's own.
abstract final class UseSmileIDSampleDeepLinks {
  static const String _gallery = 'debug/components';
  static const String _flow = 'flow';
  static const String _run = 'run';
  static const String _fullScreen = '-fullscreen';

  /// The graph link [uri] opens, or null for the plain launch and the dev gallery.
  static UseSmileIDSampleLink? linkOf(Uri uri) {
    final String path = _pathOf(uri);
    if (path.isEmpty || path == _gallery) {
      return null;
    }
    final List<String> segments = path.split('/');
    if (segments.length != 3 || segments[0] != _flow || segments[2] != _run) {
      return UseSmileIDSampleLink(path);
    }
    // One URI, two presentations: `spec/routes.json` defaults the run to full screen, which the graph names apart.
    final UseSmileIDSampleFlowRoute route =
        UseSmileIDSampleFlowRoute.byId(uri.queryParameters['route']) ??
        UseSmileIDSampleFlowRoute.fullscreen;
    return UseSmileIDSampleLink(
      route == UseSmileIDSampleFlowRoute.fullscreen
          ? '$path$_fullScreen'
          : path,
      route: route,
    );
  }

  /// Whether [uri] is the dev-only component gallery, which is in neither `spec/routes.json` nor the graph.
  static bool isGallery(Uri uri) => _pathOf(uri) == _gallery;

  /// The product a `flow/…` link runs, as its second segment names it.
  static String? productIdOf(UseSmileIDSampleLink link) {
    final List<String> segments = link.path.split('/');
    return segments.length >= 2 && segments[0] == _flow ? segments[1] : null;
  }

  static String _pathOf(Uri uri) =>
      (uri.hasAuthority ? '${uri.authority}${uri.path}' : uri.path)
          .split('/')
          .where((String segment) => segment.isNotEmpty)
          .join('/');
}
