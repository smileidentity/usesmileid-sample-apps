import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/use_smileid_sample_products_tab.dart';
import 'screens/use_smileid_sample_settings_tab.dart';
import 'screens/use_smileid_sample_verifications_tab.dart';
import 'use_smileid_sample_component_gallery.dart';
import 'use_smileid_sample_shell.dart';

/// Every path in `spec/routes.json`, written once so no call site spells one.
///
/// The three tab roots are the only ones with a screen today; the rest are here because the paths
/// are the contract four apps share, and a route helper that arrives with its screen arrives late.
abstract final class UseSmileIDSampleRoutes {
  /// The products grid, and the app's start destination.
  static const String products = '/products';

  /// The verifications list.
  static const String verifications = '/verifications';

  /// Settings.
  static const String settings = '/settings';

  /// The licences page, pushed inside the settings tab.
  static const String licenses = '/settings/licenses';

  /// The component gallery, a dev surface that is deliberately absent from `spec/routes.json`.
  static const String components = '/debug/components';

  /// One verification's detail page.
  static String verificationDetails(String jobId) => '/verifications/$jobId';

  /// The tab roots, which are the only destinations that carry a nav bar.
  static const List<String> tabRoots = <String>[
    products,
    verifications,
    settings,
  ];
}

/// Whether [location] is a tab root, which is the whole of R13's nav-bar predicate.
///
/// It takes the destination and nothing else. Testing membership of a tab's branch instead put a
/// bar on pushed screens the design draws without one, which is the defect R13 was written for.
bool useSmileIDSampleShowsNavBar(String location) =>
    UseSmileIDSampleRoutes.tabRoots.contains(location);

/// The navigation host: one indexed stack of three branches, which is R7 without hand-rolling it.
///
/// Routes pushed inside a branch keep that tab's stack; the flow and profile routes will sit above
/// the shell so they cover the bar, and arrive with the screens they show.
GoRouter useSmileIDSampleRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? UseSmileIDSampleRoutes.products,
  // Measured on a device: without this the platform's raw route WINS over initialLocation, and a
  // custom-scheme link reaches the matcher whole — 'usesmileid-sample-flutter://settings/' — which
  // matches nothing and lands on the not-found page. The caller has already folded it into a path.
  overridePlatformDefaultLocation: true,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell shell,
          ) => UseSmileIDSampleShell(shell: shell, location: state.uri.path),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: UseSmileIDSampleRoutes.products,
              builder: (_, _) => const UseSmileIDSampleProductsTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: UseSmileIDSampleRoutes.verifications,
              builder: (_, _) => const UseSmileIDSampleVerificationsTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: UseSmileIDSampleRoutes.settings,
              builder: (_, _) => const UseSmileIDSampleSettingsTab(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: UseSmileIDSampleRoutes.components,
      builder: (_, _) => const UseSmileIDSampleComponentGallery(),
    ),
  ],
);
