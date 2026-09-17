import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/use_smileid_sample_flow_form_tabs.dart';
import 'screens/use_smileid_sample_licenses_tab.dart';
import 'screens/use_smileid_sample_products_tab.dart';
import 'screens/use_smileid_sample_profile_config_tab.dart';
import 'screens/use_smileid_sample_profiles_tab.dart';
import 'screens/use_smileid_sample_settings_tab.dart';
import 'screens/use_smileid_sample_verification_details_tab.dart';
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

  /// The profiles list, above the tabs rather than inside one.
  static const String profiles = '/profiles';

  /// The scenario drawer, a LAYER over settings rather than a page of its own.
  static const String scenarioDrawer = '/debug/scenarios';

  /// The component gallery, a dev surface that is deliberately absent from `spec/routes.json`.
  static const String components = '/debug/components';

  /// One verification's detail page.
  static String verificationDetails(String jobId) => '/verifications/$jobId';

  /// One profile's own page.
  static String profileConfig(String profileId) => '/profiles/$profileId';

  /// The details every product collects before its flow.
  static String consentDetailsForm(String productId) =>
      '/flow/$productId/details';

  /// The country, ID type and number the document products need.
  static String idDetailsForm(String productId) =>
      '/flow/$productId/id-details';

  /// The country picker, which is a LAYER over the ID form rather than a page of its own.
  static String countryPicker(String productId) =>
      '/flow/$productId/id-details/country';

  /// The ID type picker, the same.
  static String idTypePicker(String productId) =>
      '/flow/$productId/id-details/id-type';

  /// The SDK flow itself.
  static String sdkFlow(String productId) => '/flow/$productId/run';

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
bool useSmileIDSampleShowsNavBar(String location) => UseSmileIDSampleRoutes
    .tabRoots
    .contains(useSmileIDSamplePageBehind(location));

/// The destination a sheet route is layered over, which is itself for every other route.
///
/// The picker paths nest under the form they cover, so they resolve to themselves and get no bar.
String useSmileIDSamplePageBehind(String location) =>
    location == UseSmileIDSampleRoutes.scenarioDrawer
    ? UseSmileIDSampleRoutes.settings
    : location;

/// The navigation host: one indexed stack of three branches, which is R7 without hand-rolling it.
///
/// Routes pushed inside a branch keep that tab's stack; the flow and profile routes will sit above
/// the shell so they cover the bar, and arrive with the screens they show.
GoRouter useSmileIDSampleRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? UseSmileIDSampleRoutes.products,
  // Measured on a device: without this the platform's raw route WINS over initialLocation.
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
              routes: <RouteBase>[
                // A CHILD of the tab root, not a sibling: the detail page belongs to this tab's stack.
                GoRoute(
                  path: ':jobId',
                  builder: (BuildContext context, GoRouterState state) =>
                      UseSmileIDSampleVerificationDetailsTab(
                        jobId: state.pathParameters['jobId']!,
                        onBack: () =>
                            context.go(UseSmileIDSampleRoutes.verifications),
                      ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: UseSmileIDSampleRoutes.settings,
              builder: (_, _) => const UseSmileIDSampleSettingsTab(),
              routes: <RouteBase>[
                // A CHILD of the tab root: the notices belong to this tab's stack, so back
                // returns to settings rather than to the start destination.
                GoRoute(
                  path: 'licenses',
                  builder: (BuildContext context, GoRouterState state) =>
                      UseSmileIDSampleLicensesTab(
                        onBack: () =>
                            context.go(UseSmileIDSampleRoutes.settings),
                      ),
                ),
              ],
            ),
            // A sheet is a LAYER over its owner, never a destination that replaces it (R12).
            GoRoute(
              path: UseSmileIDSampleRoutes.scenarioDrawer,
              builder: (_, _) =>
                  const UseSmileIDSampleSettingsTab(openDrawer: true),
            ),
          ],
        ),
      ],
    ),
    // The flow's forms, above the shell so they cover the tab bar.
    GoRoute(
      path: '/flow/:productId/details',
      builder: (BuildContext context, GoRouterState state) =>
          UseSmileIDSampleUserDetailsTab(
            productId: state.pathParameters['productId']!,
          ),
    ),
    GoRoute(
      path: '/flow/:productId/id-details',
      builder: (BuildContext context, GoRouterState state) =>
          UseSmileIDSampleKycFormTab(
            productId: state.pathParameters['productId']!,
          ),
      // A sheet is a LAYER over its owner, never a destination that replaces it (R12).
      routes: <RouteBase>[
        GoRoute(
          path: 'country',
          builder: (BuildContext context, GoRouterState state) =>
              UseSmileIDSampleKycFormTab(
                productId: state.pathParameters['productId']!,
                openSheet: UseSmileIDSamplePicker.country,
              ),
        ),
        GoRoute(
          path: 'id-type',
          builder: (BuildContext context, GoRouterState state) =>
              UseSmileIDSampleKycFormTab(
                productId: state.pathParameters['productId']!,
                openSheet: UseSmileIDSamplePicker.idType,
              ),
        ),
      ],
    ),
    // Above the shell, not inside a tab: the backlog doc rules non-root routes sit above the tabs
    // as Android has them, which gives a cold deep link one synthesised parent rather than a tab's.
    GoRoute(
      path: UseSmileIDSampleRoutes.profiles,
      builder: (BuildContext context, GoRouterState state) =>
          UseSmileIDSampleProfilesTab(
            onBack: () => context.go(UseSmileIDSampleRoutes.settings),
          ),
      routes: <RouteBase>[
        GoRoute(
          path: ':profileId',
          builder: (BuildContext context, GoRouterState state) =>
              UseSmileIDSampleProfileConfigTab(
                profileId: state.pathParameters['profileId']!,
                onBack: () => context.go(UseSmileIDSampleRoutes.profiles),
              ),
        ),
      ],
    ),
    GoRoute(
      path: UseSmileIDSampleRoutes.components,
      builder: (_, _) => const UseSmileIDSampleComponentGallery(),
    ),
  ],
);
