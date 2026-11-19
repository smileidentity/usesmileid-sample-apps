import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_njia/usesmileid_njia.dart';

import '../screens/use_smileid_sample_flow_form_tabs.dart';
import '../screens/use_smileid_sample_id_details_sheets.dart';
import '../screens/use_smileid_sample_licenses_tab.dart';
import '../screens/use_smileid_sample_products_tab.dart';
import '../screens/use_smileid_sample_profile_config_tab.dart';
import '../screens/use_smileid_sample_profile_switcher.dart';
import '../screens/use_smileid_sample_profiles_tab.dart';
import '../screens/use_smileid_sample_scan_token_tab.dart';
import '../screens/use_smileid_sample_sdk_flow_tab.dart';
import '../screens/use_smileid_sample_settings_sheets.dart';
import '../screens/use_smileid_sample_settings_tab.dart';
import '../screens/use_smileid_sample_verification_details_tab.dart';
import '../screens/use_smileid_sample_verifications_tab.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_remove_jobs.dart';
import 'use_smileid_sample_navigation.dart';
import 'use_smileid_sample_njia.dart';

/// What draws each of the graph's step kinds; a kind with no builder fails before the first frame.
final NjiaSteps<UseSmileIDSampleStep, UseSmileIDSampleFact>
useSmileIDSampleSteps = NjiaSteps<UseSmileIDSampleStep, UseSmileIDSampleFact>(
  (NjiaStepsBuilder<UseSmileIDSampleStep, UseSmileIDSampleFact> steps) => steps
    ..decorate(_page)
    ..step(
      UseSmileIDSampleStep.products,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleProductsTab(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.verifications,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleVerificationsTab(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.settings,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleSettingsTab(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.licenses,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleLicensesTab(onBack: scope.navigator.back),
    )
    ..step(
      UseSmileIDSampleStep.captureMode,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleCaptureModeStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.appearance,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleAppearanceStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.language,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleLanguageStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.scenarioDrawer,
      (_, UseSmileIDSampleStepScope scope) =>
          const UseSmileIDSampleScenarioDrawerStep(),
    )
    ..step(
      UseSmileIDSampleStep.verificationDetails,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleVerificationDetailsTab(
            jobId: scope.entry.arg ?? '',
            onBack: scope.navigator.back,
          ),
    )
    ..step(
      UseSmileIDSampleStep.profileSwitch,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleProfileSwitchStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.profiles,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleProfilesTab(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.newProfile,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleNewProfileStep(onDone: scope.navigator.back),
    )
    ..step(
      UseSmileIDSampleStep.profileConfig,
      (_, UseSmileIDSampleStepScope scope) => UseSmileIDSampleProfileConfigTab(
        profileId: scope.entry.arg ?? '',
        onBack: scope.navigator.back,
      ),
    )
    ..step(
      UseSmileIDSampleStep.scanToken,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleScanTokenTab(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.countryPicker,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleCountryPickerStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.idTypePicker,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleIdTypePickerStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.documentPicker,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleDocumentPickerStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.captureAs,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleCaptureAsStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.genericDocument,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleGenericDocumentStep(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.consentDetailsForm,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleUserDetailsTab(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.authUserId,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleAuthUserIdTab(scope: scope),
    )
    ..step(
      UseSmileIDSampleStep.idDetailsForm,
      (_, UseSmileIDSampleStepScope scope) =>
          UseSmileIDSampleKycFormTab(scope: scope),
    )
    ..step(UseSmileIDSampleStep.sdkFlow, _sdkFlow)
    ..step(UseSmileIDSampleStep.sdkFlowFullScreen, _sdkFlow),
);

/// The run, whose product is its first entry's and whose presentation is its step's.
Widget _sdkFlow(BuildContext context, UseSmileIDSampleStepScope scope) {
  final UseSmileIDSampleEngine engine =
      UseSmileIDSampleNavigationScope.engineOf(context);
  final String productId = engine.runProductId(scope.entry) ?? '';
  return UseSmileIDSampleSdkFlowTab(
    productId: productId,
    route: scope.step.kind == UseSmileIDSampleStep.sdkFlowFullScreen
        ? UseSmileIDSampleFlowRoute.fullscreen
        : UseSmileIDSampleFlowRoute.shell,
    onLeave: engine.leaveToProducts,
    onNeedsDetails: () => engine.leaveRun(
      scope.entry,
      UseSmileIDSampleStep.consentDetailsForm,
      arg: productId,
    ),
    onNeedsSession: () =>
        engine.leaveRun(scope.entry, UseSmileIDSampleStep.scanToken),
    onNeedsUserId: () => engine.leaveRun(
      scope.entry,
      UseSmileIDSampleStep.authUserId,
      arg: productId,
    ),
    onResult: (String jobId) => engine.leaveRun(
      scope.entry,
      UseSmileIDSampleStep.verificationDetails,
      arg: jobId,
    ),
  );
}

/// The steps the shell's own page drew before: the tab roots, with their bar, and the screens pushed inside a tab.
const Set<UseSmileIDSampleStep> _shellPages = <UseSmileIDSampleStep>{
  UseSmileIDSampleStep.products,
  UseSmileIDSampleStep.verifications,
  UseSmileIDSampleStep.settings,
  UseSmileIDSampleStep.licenses,
  UseSmileIDSampleStep.verificationDetails,
};

/// The page a shell step sits on; every other step draws its own, and a sheet its own panel.
Widget _page(
  BuildContext context,
  UseSmileIDSampleStepScope scope,
  Widget content,
) => _shellPages.contains(scope.step.kind)
    ? _UseSmileIDSampleShellPage(scope: scope, child: content)
    : content;

/// A tab's root, with the nav bar floating over it, or a screen pushed inside a tab, with none.
class _UseSmileIDSampleShellPage extends ConsumerWidget {
  const _UseSmileIDSampleShellPage({required this.scope, required this.child});

  final UseSmileIDSampleStepScope scope;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleNavItem? tab = useSmileIDSampleNavItemOf(
      scope.step.kind,
    );
    final UseSmileIDSampleSelection selection = ref.watch(
      useSmileIDSampleSelectionProvider,
    );
    final bool showsSelectionBar =
        tab == UseSmileIDSampleNavItem.verifications && selection.active;
    final bool showsNavBar = tab != null && !showsSelectionBar;
    return Scaffold(
      backgroundColor: UseSmileIDSampleTheme.colorsOf(context).background,
      // What publishes the bar's measured height to the body as its bottom padding.
      extendBody: showsNavBar,
      bottomNavigationBar: showsSelectionBar
          ? UseSmileIDSampleSelectionBar(
              selectedCount: selection.ids.length,
              onRemove: () => useSmileIDSampleRemoveJobs(ref, selection.ids),
            )
          : showsNavBar
          ? _UseSmileIDSampleTabBar(tab: tab, scope: scope)
          : null,
      // Top only: the bar insets the bottom itself, and doing it here too lifts it twice.
      body: SafeArea(
        bottom: false,
        child: UseSmileIDSampleTextMetrics(child: child),
      ),
    );
  }
}

/// The floating nav bar a tab's root draws, ticking on its own so the countdown rebuilds only the bar.
class _UseSmileIDSampleTabBar extends ConsumerWidget {
  const _UseSmileIDSampleTabBar({required this.tab, required this.scope});

  final UseSmileIDSampleNavItem tab;

  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleTokenSession? live = ref
        .watch(useSmileIDSampleSessionProvider)
        .live;
    final UseSmileIDSampleEngine engine =
        UseSmileIDSampleNavigationScope.engineOf(context);
    return UseSmileIDSampleNavBar(
      selected: tab,
      // Re-selecting the showing tab pops it to its root, as the platform does.
      onSelect: (UseSmileIDSampleNavItem item) =>
          engine.select(useSmileIDSampleStepOf(item).name),
      onTokenTap: () => scope.navigator.goStep(UseSmileIDSampleStep.scanToken),
      sessionProgress: live?.progress(ref.watch(useSmileIDSampleClockProvider)),
    );
  }
}

/// The tab root each nav bar item selects.
UseSmileIDSampleStep useSmileIDSampleStepOf(UseSmileIDSampleNavItem item) =>
    switch (item) {
      UseSmileIDSampleNavItem.products => UseSmileIDSampleStep.products,
      UseSmileIDSampleNavItem.verifications =>
        UseSmileIDSampleStep.verifications,
      UseSmileIDSampleNavItem.settings => UseSmileIDSampleStep.settings,
    };

/// The nav bar item whose root [step] is, or null for a step above a root.
UseSmileIDSampleNavItem? useSmileIDSampleNavItemOf(UseSmileIDSampleStep step) =>
    UseSmileIDSampleNavItem.values
        .where(
          (UseSmileIDSampleNavItem it) => useSmileIDSampleStepOf(it) == step,
        )
        .firstOrNull;
