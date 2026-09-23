import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import 'screens/use_smileid_sample_flow_form_tabs.dart';
import 'screens/use_smileid_sample_licenses_tab.dart';
import 'screens/use_smileid_sample_products_tab.dart';
import 'screens/use_smileid_sample_profile_config_tab.dart';
import 'screens/use_smileid_sample_profiles_tab.dart';
import 'screens/use_smileid_sample_scan_token_tab.dart';
import 'screens/use_smileid_sample_sdk_flow_tab.dart';
import 'screens/use_smileid_sample_settings_tab.dart';
import 'screens/use_smileid_sample_verification_details_tab.dart';
import 'screens/use_smileid_sample_verifications_tab.dart';
import 'use_smileid_sample_component_gallery.dart';
import 'use_smileid_sample_launch.dart';
import 'use_smileid_sample_shell.dart';

/// Every path in `spec/routes.json`, written once so no call site spells one.
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

  /// The profile-switch sheet, a LAYER over products: its path sits under profiles, its owner does not.
  static const String profileSwitch = '/profiles/switch';

  /// The scenario drawer, a LAYER over settings rather than a page of its own.
  static const String scenarioDrawer = '/debug/scenarios';

  /// The token scanner, pushed above the shell.
  static const String scanToken = '/token/scan';

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

/// Back one level, or to the screen that owns this one when a deep link left nothing to pop.
void useSmileIDSampleBack(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(fallback);
}

/// Whether [location] is a tab root, which is the whole of R13's nav-bar predicate.
bool useSmileIDSampleShowsNavBar(String location) => UseSmileIDSampleRoutes
    .tabRoots
    .contains(useSmileIDSamplePageBehind(location));

/// The destination a sheet route is layered over, which is itself for every other route.
String useSmileIDSamplePageBehind(String location) => switch (location) {
  UseSmileIDSampleRoutes.scenarioDrawer => UseSmileIDSampleRoutes.settings,
  UseSmileIDSampleRoutes.profileSwitch => UseSmileIDSampleRoutes.products,
  _ => location,
};

/// Folds a whole custom-scheme link back into a path, or null to leave an in-app route alone.
String? useSmileIDSampleFoldPlatformLink(
  BuildContext context,
  GoRouterState state,
) {
  // Measured on a device: only the cold start parses the link, so a warm one arrives whole.
  if (!state.uri.hasScheme) {
    return null;
  }
  // The query rides along per spec/routes.json; seeding runs once in main() and cannot re-fire.
  final String path = UseSmileIDSampleLaunch(state.uri.toString()).location;
  return state.uri.hasQuery ? '$path?${state.uri.query}' : path;
}

/// The navigation host: one indexed stack of three branches, which is R7 without hand-rolling it.
GoRouter useSmileIDSampleRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation ?? UseSmileIDSampleRoutes.products,
  // Measured on a device: without this the platform's raw route WINS over initialLocation.
  overridePlatformDefaultLocation: true,
  redirect: useSmileIDSampleFoldPlatformLink,
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
              pageBuilder: (_, _) => _ownerPage(
                UseSmileIDSampleRoutes.products,
                const UseSmileIDSampleProductsTab(),
              ),
            ),
            // A sheet is a LAYER over its owner, and matched here before /profiles/:profileId can.
            GoRoute(
              path: UseSmileIDSampleRoutes.profileSwitch,
              pageBuilder: (_, _) => _ownerPage(
                UseSmileIDSampleRoutes.products,
                const UseSmileIDSampleProductsTab(openSwitch: true),
              ),
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
              pageBuilder: (_, _) => _ownerPage(
                UseSmileIDSampleRoutes.settings,
                const UseSmileIDSampleSettingsTab(),
              ),
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
              pageBuilder: (_, _) => _ownerPage(
                UseSmileIDSampleRoutes.settings,
                const UseSmileIDSampleSettingsTab(openDrawer: true),
              ),
            ),
          ],
        ),
      ],
    ),
    // Siblings because `spec/routes.json` fixes the paths; pushing them is what makes the stack.
    GoRoute(
      path: '/flow/:productId/details',
      builder: (BuildContext context, GoRouterState state) =>
          UseSmileIDSampleUserDetailsTab(
            productId: state.pathParameters['productId']!,
          ),
    ),
    GoRoute(
      path: '/flow/:productId/run',
      // Turned back before it mounts: leaving a route that replaced the shell duplicates its key.
      redirect: (BuildContext context, GoRouterState state) =>
          UseSmileIDSampleProduct.values.any(
            (UseSmileIDSampleProduct it) =>
                it.id == state.pathParameters['productId'],
          )
          ? null
          : UseSmileIDSampleRoutes.products,
      builder: (BuildContext context, GoRouterState state) {
        final String productId = state.pathParameters['productId']!;
        return UseSmileIDSampleSdkFlowTab(
          productId: productId,
          onLeave: () => context.go(UseSmileIDSampleRoutes.products),
          onNeedsDetails: () =>
              context.go(UseSmileIDSampleRoutes.consentDetailsForm(productId)),
          onNeedsSession: () => context.go(UseSmileIDSampleRoutes.scanToken),
          // `go`, not a pop: the wizard beneath must not be reachable back INTO from the result.
          onResult: (String jobId) =>
              context.go(UseSmileIDSampleRoutes.verificationDetails(jobId)),
        );
      },
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
            onBack: () =>
                useSmileIDSampleBack(context, UseSmileIDSampleRoutes.settings),
          ),
      routes: <RouteBase>[
        GoRoute(
          path: ':profileId',
          builder: (BuildContext context, GoRouterState state) =>
              UseSmileIDSampleProfileConfigTab(
                profileId: state.pathParameters['profileId']!,
                onBack: () => useSmileIDSampleBack(
                  context,
                  UseSmileIDSampleRoutes.profiles,
                ),
              ),
        ),
      ],
    ),
    GoRoute(
      path: UseSmileIDSampleRoutes.scanToken,
      builder: (_, _) => const UseSmileIDSampleScanTokenTab(),
    ),
    GoRoute(
      path: UseSmileIDSampleRoutes.components,
      builder: (_, _) => const UseSmileIDSampleComponentGallery(),
    ),
  ],
);

/// One page for an owner and its sheet link: keyed by the owner, so moving between them updates it.
Page<void> _ownerPage(String owner, Widget child) => MaterialPage<void>(
  key: ValueKey<String>(owner),
  restorationId: owner,
  child: child,
);
