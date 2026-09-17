import 'package:sample_ui/sample_ui.dart';

import 'use_smileid_sample_routes.dart';

/// The link the platform launched this process at, or '/' when it was launched from the icon.
///
/// `spec/launch-args.json` settles the Flutter mechanism as a COLD-START deep link, read once and
/// never from the stream of later ones. This is that initial link: the engine hands it over before
/// the first frame, so no plugin and no native shim is involved, which is the point of the ruling.
class UseSmileIDSampleLaunch {
  /// Takes the platform's raw route, which on Android is the launching intent's data.
  UseSmileIDSampleLaunch(String platformRoute)
    : _uri = Uri.tryParse(platformRoute) ?? Uri(path: platformRoute);

  final Uri _uri;

  /// Where the router should open, with the scheme and host folded back into the path.
  ///
  /// A custom-scheme link arrives whole — `usesmileid-sample-flutter://settings` — and go_router
  /// matches on the PATH, so handing it over unchanged fails to match any route and lands the app
  /// on its not-found page. Android's own table writes the first segment as the authority, so the
  /// authority is the first path segment, not something to discard.
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
  UseSmileIDSampleLaunchArgs get args => UseSmileIDSampleLaunchArgs(
    seedJobs: _flag('seedJobs'),
    seedProfiles: _flag('seedProfiles'),
    probes: _flag('probes'),
  );

  /// One boolean argument, true only for an explicit true; anything else is the default.
  bool _flag(String name) =>
      _uri.queryParameters[name]?.trim().toLowerCase() == 'true';
}
