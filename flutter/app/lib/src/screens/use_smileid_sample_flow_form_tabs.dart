import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../catalogue/use_smileid_sample_catalogue_providers.dart';
import '../flow/use_smileid_sample_token_binding_rules.dart';
import '../navigation/use_smileid_sample_navigation.dart';
import '../navigation/use_smileid_sample_njia.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_journey.dart';
import 'use_smileid_sample_above_shell_page.dart';

/// The details every product collects before its flow, filled from the profile the run is for.
class UseSmileIDSampleUserDetailsTab extends ConsumerStatefulWidget {
  /// The form for [scope]'s entry, which the run's product titles.
  const UseSmileIDSampleUserDetailsTab({required this.scope, super.key});

  /// The form's entry, which Continue goes on from.
  final UseSmileIDSampleStepScope scope;

  @override
  ConsumerState<UseSmileIDSampleUserDetailsTab> createState() =>
      _UseSmileIDSampleUserDetailsTabState();
}

class _UseSmileIDSampleUserDetailsTabState
    extends ConsumerState<UseSmileIDSampleUserDetailsTab> {
  late final UseSmileIDSampleCatalogueStore _catalogue = ref.read(
    useSmileIDSampleCatalogueStoreProvider,
  );

  /// Read once: a page still animating out after a run leaves would find no product.
  late final String _productId = _runProductId(context, widget.scope);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final UseSmileIDSampleProfile? active = ref
          .read(useSmileIDSampleProfilesProvider)
          .active;
      if (active != null) {
        ref.read(useSmileIDSampleFormsProvider.notifier).fillFrom(active);
      }
      // A deep link lands here without the product tap that asks ahead.
      useSmileIDSampleEnsureEnabled(
        _catalogue,
        useSmileIDSampleProductOf(_productId),
        ref.read(useSmileIDSampleSessionProvider).live,
      );
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    // The configuration can arrive after the form opens, and it decides which rows show.
    listenable: _catalogue,
    builder: (BuildContext context, _) => _form(context),
  );

  Widget _form(BuildContext context) {
    final String productId = _productId;
    final UseSmileIDSampleProduct? product = useSmileIDSampleProductOf(
      productId,
    );
    final UseSmileIDSampleForms forms = ref.watch(
      useSmileIDSampleFormsProvider,
    );
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    final UseSmileIDSampleTokenSession? live =
        ref.watch(useSmileIDSampleSessionProvider).live == null
        ? null
        : useSmileIDSampleLiveTokenSession(ref);
    final UseSmileIDSampleUserDetailsRequirement requirement =
        useSmileIDSampleUserDetailsRequirementFor(
          live?.bindings,
          product,
          _catalogue.fieldsToCollectFor(live?.id),
          _catalogue.idTypeFieldsFor(live?.id),
        );
    final UseSmileIDSampleFormsNotifier edits = ref.read(
      useSmileIDSampleFormsProvider.notifier,
    );
    void back() => unawaited(widget.scope.navigator.back());
    return UseSmileIDSampleAboveShellPage(
      child: UseSmileIDSampleUserDetailsScreen(
        // The raw id for a product this build does not know, so a stale link names what it looked
        // for rather than showing an empty title.
        title: product?.label ?? productId,
        details: forms.userDetails,
        requirement: requirement,
        onBack: back,
        onFieldChanged: edits.setUserField,
        onContinue: () {
          if (forms.saveToProfile) {
            ref
                .read(useSmileIDSampleProfilesProvider.notifier)
                .keep(
                  forms.userDetails,
                  organisation: forms.organisation,
                  requirement: requirement,
                );
          }
          unawaited(widget.scope.navigator.next());
        },
        profile: profiles.active,
        profileIndex: profiles.activeIndex,
        onProfileTap: () => unawaited(
          widget.scope.navigator.goStep(UseSmileIDSampleStep.profileSwitch),
        ),
        saveToProfile: forms.saveToProfile,
        onSaveToProfileChanged: edits.setSaveToProfile,
        organisation: forms.organisation,
        onOrganisationChanged: edits.setOrganisation,
      ),
    );
  }
}

/// SmartSelfie Authentication's user ID, typed or picked from runs that enrolled one; the run never makes one up.
class UseSmileIDSampleAuthUserIdTab extends ConsumerWidget {
  /// The form for [scope]'s entry, in a SmartSelfie Authentication run.
  const UseSmileIDSampleAuthUserIdTab({required this.scope, super.key});

  /// The form's entry, which Continue goes on from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleForms forms = ref.watch(
      useSmileIDSampleFormsProvider,
    );
    final List<UseSmileIDSampleJob> jobs =
        ref.watch(useSmileIDSampleJobsProvider).value ??
        const <UseSmileIDSampleJob>[];
    final UseSmileIDSampleTokenSession? live = useSmileIDSampleLiveSession(
      ref.watch(useSmileIDSampleSessionProvider).live,
      DateTime.now().millisecondsSinceEpoch,
    );
    void back() => unawaited(scope.navigator.back());
    return UseSmileIDSampleAboveShellPage(
      child: UseSmileIDSampleAuthUserIdScreen(
        userId: forms.authUserId,
        // A user is enrolled under one partner in one environment, so another's IDs would authenticate nobody.
        previousUsers: useSmileIDSamplePreviousAuthUsers(
          jobs,
          partnerId: live?.partnerId,
          sandbox: useSmileIDSampleUseSandbox(live),
        ),
        onUserIdChanged: ref
            .read(useSmileIDSampleFormsProvider.notifier)
            .setAuthUserId,
        onRegister: () {
          ref
              .read(useSmileIDSampleFormsProvider.notifier)
              .startRun(ref.read(useSmileIDSampleProfilesProvider).active);
          const UseSmileIDSampleProduct enrolment =
              UseSmileIDSampleProduct.smartSelfieEnrollment;
          final UseSmileIDSampleEngine engine =
              UseSmileIDSampleNavigationScope.engineOf(context);
          final int? start = engine.runStart(scope.entry)?.id;
          final UseSmileIDSampleRunEntry? run = useSmileIDSampleEntryFor(
            ref,
            engine.graph,
            enrolment,
          );
          // In the authentication run's place, so back from the enrolment returns to products.
          unawaited(
            run == null
                ? scope.navigator.go(
                    UseSmileIDSampleStep.scanToken.name,
                    replace: start,
                  )
                : engine.startRun(scope.entry, enrolment, run, replace: start),
          );
        },
        onBack: back,
        // `next` from this entry only, so a second quick tap is stale and starts no second run.
        onContinue: () => unawaited(scope.navigator.next()),
      ),
    );
  }
}

/// The ID-details form; its pickers and capture sheets are sheet steps over it.
class UseSmileIDSampleKycFormTab extends ConsumerStatefulWidget {
  /// The form for [scope]'s entry.
  const UseSmileIDSampleKycFormTab({required this.scope, super.key});

  /// The form's entry, which its pickers and Continue go from.
  final UseSmileIDSampleStepScope scope;

  @override
  ConsumerState<UseSmileIDSampleKycFormTab> createState() =>
      _UseSmileIDSampleKycFormTabState();
}

class _UseSmileIDSampleKycFormTabState
    extends ConsumerState<UseSmileIDSampleKycFormTab> {
  late final UseSmileIDSampleCatalogueStore _catalogue = ref.read(
    useSmileIDSampleCatalogueStoreProvider,
  );

  /// Read once: a page still animating out after a run leaves would find no product.
  late final String _productId = _runProductId(context, widget.scope);

  UseSmileIDSampleCatalogueFamily get _family =>
      useSmileIDSampleFamilyOf(useSmileIDSampleProductOf(_productId));

  @override
  void initState() {
    super.initState();
    // After the first frame, because a sheet cannot be presented while this is still building —
    // and once only, so returning here later does not replay the link's sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // A deep link lands here without the product tap that fetches ahead, so the form starts it.
      _ensureCatalogue();
      final UseSmileIDSampleProduct? product = useSmileIDSampleProductOf(
        _productId,
      );
      if (product != null) {
        ref
            .read(useSmileIDSampleFormsProvider.notifier)
            .keepDocumentListedOn(product);
      }
    });
  }

  @override
  void dispose() {
    // After the frame: stopping notifies, and nothing may rebuild while this tree is torn down.
    scheduleMicrotask(_catalogue.stop);
    super.dispose();
  }

  /// Also from every picker: the token button relinks, and the lists follow the new session.
  void _ensureCatalogue() => useSmileIDSampleEnsureCatalogue(
    ref,
    useSmileIDSampleProductOf(_productId),
  );

  /// After the frame, since a notifier cannot change while this builds; nothing is scheduled when every pick is still enabled.
  void _keepOnlyEnabled(UseSmileIDSampleIdDetails details) {
    final (List<UseSmileIDSampleCountry>?, List<UseSmileIDSampleDocument>?)
    lists = _enabledLists(details);
    if (identical(details.withEnabledOnly(lists.$1, lists.$2), details)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Read again: the first frame's callback may have just reset a previous session's list.
      final UseSmileIDSampleFormsNotifier forms = ref.read(
        useSmileIDSampleFormsProvider.notifier,
      );
      final (List<UseSmileIDSampleCountry>?, List<UseSmileIDSampleDocument>?)
      fresh = _enabledLists(ref.read(useSmileIDSampleFormsProvider).idDetails);
      forms.keepOnlyEnabled(fresh.$1, fresh.$2);
    });
  }

  (List<UseSmileIDSampleCountry>?, List<UseSmileIDSampleDocument>?)
  _enabledLists(UseSmileIDSampleIdDetails details) {
    const UseSmileIDSampleProduct product =
        UseSmileIDSampleProduct.enhancedDocumentVerification;
    final String? code = details.country?.code;
    return (
      _catalogue.countries(_family, product: product).settledItems,
      code == null
          ? null
          : _catalogue.documents(code, product: product).settledItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProduct? product = useSmileIDSampleProductOf(
      _productId,
    );
    final UseSmileIDSampleIdDetails details = ref
        .watch(useSmileIDSampleFormsProvider)
        .idDetails;
    final UseSmileIDSampleFormsNotifier edits = ref.read(
      useSmileIDSampleFormsProvider.notifier,
    );
    ref.listen<String?>(
      useSmileIDSampleSessionProvider.select(
        (UseSmileIDSampleSessionRecord s) => s.live?.id,
      ),
      (String? _, String? _) => _ensureCatalogue(),
    );
    void back() => unawaited(widget.scope.navigator.back());
    void go(UseSmileIDSampleStep step) =>
        unawaited(widget.scope.navigator.goStep(step));
    return UseSmileIDSampleAboveShellPage(
      child: ListenableBuilder(
        listenable: _catalogue,
        builder: (BuildContext context, Widget? _) {
          final String? country = details.country?.code;
          if (product == UseSmileIDSampleProduct.enhancedDocumentVerification) {
            _keepOnlyEnabled(details);
          }
          return UseSmileIDSampleKycFormScreen(
            title: product?.label ?? _productId,
            family: _family,
            details: details,
            countryListLoading:
                country != null &&
                switch (_family) {
                  UseSmileIDSampleCatalogueFamily.kyc =>
                    _catalogue.idTypes(country).isLoading,
                  UseSmileIDSampleCatalogueFamily.document =>
                    _catalogue
                        .documents(
                          country,
                          product:
                              product ??
                              UseSmileIDSampleProduct.documentVerification,
                        )
                        .isLoading,
                  UseSmileIDSampleCatalogueFamily.passport => false,
                },
            onBack: back,
            onPickCountry: () => go(UseSmileIDSampleStep.countryPicker),
            onPickIdType: () => go(UseSmileIDSampleStep.idTypePicker),
            onPickDocument: () => go(UseSmileIDSampleStep.documentPicker),
            onPickCaptureAs: () => go(UseSmileIDSampleStep.captureAs),
            onIdNumberChanged: edits.setIdNumber,
            // `next`, the graph's step after this form, which is the run.
            onContinue: () => unawaited(widget.scope.navigator.next()),
            onScanToken: () => go(UseSmileIDSampleStep.scanToken),
          );
        },
      ),
    );
  }
}

/// The product the run [scope]'s entry belongs to, by id.
String _runProductId(BuildContext context, UseSmileIDSampleStepScope scope) =>
    UseSmileIDSampleNavigationScope.engineOf(
      context,
    ).runProductId(scope.entry) ??
    '';

/// Starts the lists for [product] under the live session, or keeps the ones already started.
void useSmileIDSampleEnsureCatalogue(
  WidgetRef ref,
  UseSmileIDSampleProduct? product,
) {
  final UseSmileIDSampleTokenSession? live = ref
      .read(useSmileIDSampleSessionProvider)
      .live;
  final UseSmileIDSampleCatalogueStore catalogue =
      ref.read(useSmileIDSampleCatalogueStoreProvider)..ensure(
        useSmileIDSampleCatalogueEnvironment(live),
        useSmileIDSampleCatalogueLocale(),
      );
  useSmileIDSampleEnsureEnabled(catalogue, product, live);
}

/// The catalogue family [product]'s pickers list, the KYC one for a product this build does not know.
UseSmileIDSampleCatalogueFamily useSmileIDSampleFamilyOf(
  UseSmileIDSampleProduct? product,
) =>
    (product == null ? null : useSmileIDSampleCatalogueFamily(product)) ??
    UseSmileIDSampleCatalogueFamily.kyc;
