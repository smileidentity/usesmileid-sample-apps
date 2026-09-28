import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../catalogue/use_smileid_sample_catalogue_providers.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import '../use_smileid_sample_journey.dart';
import '../use_smileid_sample_routes.dart';
import 'use_smileid_sample_above_shell_page.dart';
import 'use_smileid_sample_profile_switcher.dart';

/// The details every product collects before its flow, filled from the profile the run is for.
class UseSmileIDSampleUserDetailsTab extends ConsumerStatefulWidget {
  /// [productId] comes from the route and titles the page.
  const UseSmileIDSampleUserDetailsTab({required this.productId, super.key});

  /// The product whose flow this precedes.
  final String productId;

  @override
  ConsumerState<UseSmileIDSampleUserDetailsTab> createState() =>
      _UseSmileIDSampleUserDetailsTabState();
}

class _UseSmileIDSampleUserDetailsTabState
    extends ConsumerState<UseSmileIDSampleUserDetailsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final UseSmileIDSampleProfile? active = ref
          .read(useSmileIDSampleProfilesProvider)
          .active;
      if (mounted && active != null) {
        ref.read(useSmileIDSampleFormsProvider.notifier).fillFrom(active);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String productId = widget.productId;
    final UseSmileIDSampleProduct? product = _productFor(productId);
    final UseSmileIDSampleForms forms = ref.watch(
      useSmileIDSampleFormsProvider,
    );
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    final UseSmileIDSampleUserDetailsRequirement requirement =
        useSmileIDSampleUserDetailsRequirement(
          ref.watch(useSmileIDSampleSessionProvider).live == null
              ? null
              : useSmileIDSampleLiveBindings(ref),
        );
    final UseSmileIDSampleFormsNotifier edits = ref.read(
      useSmileIDSampleFormsProvider.notifier,
    );
    void back() =>
        useSmileIDSampleBack(context, UseSmileIDSampleRoutes.products);
    return UseSmileIDSampleAboveShellPage(
      onBack: back,
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
          context.push(
            product == null
                ? UseSmileIDSampleRoutes.sdkFlow(productId)
                : UseSmileIDSampleJourney.afterUserDetails(
                    product,
                    useSmileIDSampleLiveBindings(ref),
                  ),
          );
        },
        profile: profiles.active,
        profileIndex: profiles.activeIndex,
        onProfileTap: () =>
            showUseSmileIDSampleProfileSwitch(context, ref, overForm: true),
        saveToProfile: forms.saveToProfile,
        onSaveToProfileChanged: edits.setSaveToProfile,
        organisation: forms.organisation,
        onOrganisationChanged: edits.setOrganisation,
      ),
    );
  }
}

/// The ID-details form, with its pickers and capture sheets as layers over it.
class UseSmileIDSampleKycFormTab extends ConsumerStatefulWidget {
  /// [openSheet] names a sheet a deep link asked for, so the link opens this page with it up.
  const UseSmileIDSampleKycFormTab({
    required this.productId,
    this.openSheet,
    super.key,
  });

  /// The product whose flow this precedes.
  final String productId;

  /// Which sheet to open on arrival, if any.
  final UseSmileIDSamplePicker? openSheet;

  @override
  ConsumerState<UseSmileIDSampleKycFormTab> createState() =>
      _UseSmileIDSampleKycFormTabState();
}

class _UseSmileIDSampleKycFormTabState
    extends ConsumerState<UseSmileIDSampleKycFormTab> {
  late final UseSmileIDSampleCatalogueStore _catalogue = ref.read(
    useSmileIDSampleCatalogueStoreProvider,
  );

  UseSmileIDSampleCatalogueFamily get _family {
    final UseSmileIDSampleProduct? product = _productFor(widget.productId);
    return (product == null
            ? null
            : useSmileIDSampleCatalogueFamily(product)) ??
        UseSmileIDSampleCatalogueFamily.kyc;
  }

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
      _catalogue.ensure(
        useSmileIDSampleCatalogueEnvironment(
          ref.read(useSmileIDSampleSessionProvider).live,
        ),
        useSmileIDSampleCatalogueLocale(),
      );
      final UseSmileIDSamplePicker? asked = widget.openSheet;
      if (asked != null) {
        _openFromLink(asked);
      }
    });
  }

  @override
  void dispose() {
    // After the frame: stopping notifies, and nothing may rebuild while this tree is torn down.
    scheduleMicrotask(_catalogue.stop);
    super.dispose();
  }

  /// A link can ask for a second-level sheet before its trigger could open; refused, not held until later.
  void _openFromLink(UseSmileIDSamplePicker asked) {
    final UseSmileIDSampleIdDetails details = ref
        .read(useSmileIDSampleFormsProvider)
        .idDetails;
    switch (asked) {
      case UseSmileIDSamplePicker.country:
        _pickCountry();
      case UseSmileIDSamplePicker.idType:
        if (details.country != null) {
          _pickIdType();
        }
      case UseSmileIDSamplePicker.document:
        if (details.country != null) {
          _pickDocument();
        }
      case UseSmileIDSamplePicker.captureAs:
        if (details.document != null) {
          _pickCaptureAs();
        }
      case UseSmileIDSamplePicker.genericDocument:
        _buildGenericDocument();
    }
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProduct? product = _productFor(widget.productId);
    final UseSmileIDSampleIdDetails details = ref
        .watch(useSmileIDSampleFormsProvider)
        .idDetails;
    final UseSmileIDSampleFormsNotifier edits = ref.read(
      useSmileIDSampleFormsProvider.notifier,
    );
    void back() => useSmileIDSampleBack(
      context,
      UseSmileIDSampleRoutes.consentDetailsForm(widget.productId),
    );
    return UseSmileIDSampleAboveShellPage(
      onBack: back,
      child: ListenableBuilder(
        listenable: _catalogue,
        builder: (BuildContext context, Widget? _) {
          final String? country = details.country?.code;
          return UseSmileIDSampleKycFormScreen(
            title: product?.label ?? widget.productId,
            family: _family,
            details: details,
            countryListLoading:
                country != null &&
                switch (_family) {
                  UseSmileIDSampleCatalogueFamily.kyc =>
                    _catalogue.idTypes(country).isLoading,
                  UseSmileIDSampleCatalogueFamily.document =>
                    _catalogue.documents(country).isLoading,
                },
            onBack: back,
            onPickCountry: _pickCountry,
            onPickIdType: _pickIdType,
            onPickDocument: _pickDocument,
            onPickCaptureAs: _pickCaptureAs,
            onIdNumberChanged: edits.setIdNumber,
            // Through the journey, the one place the step order lives.
            onContinue: () => context.push(
              product == null
                  ? UseSmileIDSampleRoutes.sdkFlow(widget.productId)
                  : UseSmileIDSampleJourney.afterIdDetails(product),
            ),
            onScanToken: () => context.push(UseSmileIDSampleRoutes.scanToken),
          );
        },
      ),
    );
  }

  /// A sheet whose list may still be arriving, so it rebuilds as the store and the form change.
  Future<void> _catalogueSheet(
    String testId,
    Widget Function(
      BuildContext sheetContext,
      UseSmileIDSampleIdDetails details,
    )
    body,
  ) => showUseSmileIDSampleSheet<void>(
    context: context,
    testId: testId,
    builder: (BuildContext sheetContext) => ListenableBuilder(
      listenable: _catalogue,
      builder: (BuildContext _, Widget? _) => Consumer(
        builder: (BuildContext _, WidgetRef ref, Widget? _) => body(
          sheetContext,
          ref.watch(useSmileIDSampleFormsProvider).idDetails,
        ),
      ),
    ),
  );

  Future<void> _pickCountry() => _catalogueSheet(
    UseSmileIDSampleTestIds.countrySheet,
    (BuildContext sheetContext, UseSmileIDSampleIdDetails details) =>
        UseSmileIDSampleCountryPickerSheet(
          catalogue: _catalogue.countries(_family),
          selected: details.country,
          onRetry: _catalogue.retry,
          onSelect: (UseSmileIDSampleCountry country) {
            ref
                .read(useSmileIDSampleFormsProvider.notifier)
                .setCountry(country);
            Navigator.of(sheetContext).pop();
          },
        ),
  );

  Future<void> _pickIdType() => _catalogueSheet(
    UseSmileIDSampleTestIds.idTypeSheet,
    (BuildContext sheetContext, UseSmileIDSampleIdDetails details) =>
        UseSmileIDSampleIdTypePickerSheet(
          country: details.country,
          catalogue: _catalogue.idTypes(details.country?.code ?? ''),
          selected: details.idType,
          onRetry: _catalogue.retry,
          onSelect: (UseSmileIDSampleKycIdType idType) {
            ref.read(useSmileIDSampleFormsProvider.notifier).setIdType(idType);
            Navigator.of(sheetContext).pop();
          },
        ),
  );

  Future<void> _pickDocument() => _catalogueSheet(
    UseSmileIDSampleTestIds.documentSheet,
    (BuildContext sheetContext, UseSmileIDSampleIdDetails details) =>
        UseSmileIDSampleDocumentPickerSheet(
          country: details.country,
          catalogue: _catalogue.documents(details.country?.code ?? ''),
          selected: details.document,
          onRetry: _catalogue.retry,
          onSelect: (UseSmileIDSampleDocument document) {
            ref
                .read(useSmileIDSampleFormsProvider.notifier)
                .setDocument(document);
            Navigator.of(sheetContext).pop();
          },
        ),
  );

  Future<void> _pickCaptureAs() async {
    UseSmileIDSampleCaptureAs? chosen;
    await showUseSmileIDSampleSheet<void>(
      context: context,
      title: 'Capture as',
      testId: UseSmileIDSampleTestIds.captureAsSheet,
      builder: (BuildContext sheetContext) => UseSmileIDSampleCaptureAsSheet(
        selected: ref.read(useSmileIDSampleFormsProvider).idDetails.captureAs,
        onSelect: (UseSmileIDSampleCaptureAs option) {
          chosen = option;
          Navigator.of(sheetContext).pop();
        },
      ),
    );
    if (!mounted || chosen == null) {
      return;
    }
    // Generic document hands over to its own sheet, which is what keeps it; the others are kept at once.
    if (chosen == UseSmileIDSampleCaptureAs.genericDocument) {
      await _buildGenericDocument();
    } else {
      ref.read(useSmileIDSampleFormsProvider.notifier).setCaptureAs(chosen!);
    }
  }

  Future<void> _buildGenericDocument() => showUseSmileIDSampleSheet<void>(
    context: context,
    title: 'Generic document',
    testId: UseSmileIDSampleTestIds.genericDocumentSheet,
    builder: (BuildContext sheetContext) =>
        UseSmileIDSampleGenericDocumentSheet(
          initial: ref
              .read(useSmileIDSampleFormsProvider)
              .idDetails
              .genericDocument,
          onDone: (UseSmileIDSampleGenericDocument genericDocument) {
            ref
                .read(useSmileIDSampleFormsProvider.notifier)
                .setGenericDocument(genericDocument);
            Navigator.of(sheetContext).pop();
          },
        ),
  );
}

/// Which sheet a deep link asked for.
enum UseSmileIDSamplePicker {
  /// The country picker.
  country,

  /// The ID type picker.
  idType,

  /// The document picker.
  document,

  /// The capture-as sheet.
  captureAs,

  /// The generic-document sheet.
  genericDocument,
}

/// The product with this id, or null for one this build does not know.
UseSmileIDSampleProduct? _productFor(String productId) {
  for (final UseSmileIDSampleProduct product
      in UseSmileIDSampleProduct.values) {
    if (product.id == productId) {
      return product;
    }
  }
  return null;
}
