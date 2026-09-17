import 'package:go_router/go_router.dart';

import 'use_smileid_sample_component_gallery.dart';

/// The navigation host.
///
/// One route today, and deliberately not a deep-link path: `spec/routes.json` owns the journey's
/// sixteen, and the per-tab shell arrives with the screens it hosts rather than as three empty tabs.
GoRouter useSmileIDSampleRouter() => GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (_, _) => const UseSmileIDSampleComponentGallery(),
    ),
  ],
);
