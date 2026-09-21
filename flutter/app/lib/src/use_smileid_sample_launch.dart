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
