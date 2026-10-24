import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../catalogue/use_smileid_sample_catalogue_providers.dart';
import '../navigation/use_smileid_sample_navigation.dart';
import '../navigation/use_smileid_sample_njia.dart';
import '../state/use_smileid_sample_forms.dart';
import '../use_smileid_sample_journey.dart';
import 'use_smileid_sample_flow_form_tabs.dart';

/// The country picker over the ID-details form.
class UseSmileIDSampleCountryPickerStep extends StatelessWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleCountryPickerStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context) => _UseSmileIDSampleCatalogueSheet(
    scope: scope,
    testId: UseSmileIDSampleTestIds.countrySheet,
    body:
        (
          UseSmileIDSampleCatalogueStore catalogue,
          UseSmileIDSampleProduct? product,
          UseSmileIDSampleIdDetails details,
          UseSmileIDSampleFormsNotifier forms,
        ) => UseSmileIDSampleCountryPickerSheet(
          catalogue: catalogue.countries(
            useSmileIDSampleFamilyOf(product),
            product: product,
          ),
          selected: details.country,
          onRetry: catalogue.retry,
          onSelect: (UseSmileIDSampleCountry country) {
            forms.setCountry(country);
            unawaited(scope.navigator.back());
          },
        ),
  );
}

/// The ID type picker, which needs a country first; one opened before a country is picked closes.
class UseSmileIDSampleIdTypePickerStep extends StatelessWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleIdTypePickerStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context) => _UseSmileIDSampleCatalogueSheet(
    scope: scope,
    testId: UseSmileIDSampleTestIds.idTypeSheet,
    needs: (UseSmileIDSampleIdDetails details) => details.country != null,
    body:
        (
          UseSmileIDSampleCatalogueStore catalogue,
          UseSmileIDSampleProduct? _,
          UseSmileIDSampleIdDetails details,
          UseSmileIDSampleFormsNotifier forms,
        ) => UseSmileIDSampleIdTypePickerSheet(
          country: details.country,
          catalogue: catalogue.idTypes(details.country?.code ?? ''),
          selected: details.idType,
          onRetry: catalogue.retry,
          onSelect: (UseSmileIDSampleKycIdType idType) {
            forms.setIdType(idType);
            unawaited(scope.navigator.back());
          },
        ),
  );
}

/// The document picker, which needs a country first; one opened before a country is picked closes.
class UseSmileIDSampleDocumentPickerStep extends StatelessWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleDocumentPickerStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context) => _UseSmileIDSampleCatalogueSheet(
    scope: scope,
    testId: UseSmileIDSampleTestIds.documentSheet,
    needs: (UseSmileIDSampleIdDetails details) => details.country != null,
    body:
        (
          UseSmileIDSampleCatalogueStore catalogue,
          UseSmileIDSampleProduct? product,
          UseSmileIDSampleIdDetails details,
          UseSmileIDSampleFormsNotifier forms,
        ) => UseSmileIDSampleDocumentPickerSheet(
          country: details.country,
          catalogue: catalogue.documents(
            details.country?.code ?? '',
            product: product ?? UseSmileIDSampleProduct.documentVerification,
          ),
          selected: details.document,
          onRetry: catalogue.retry,
          onSelect: (UseSmileIDSampleDocument document) {
            forms.setDocument(document);
            unawaited(scope.navigator.back());
          },
        ),
  );
}

/// The capture-as sheet, which needs a document first; generic document hands over to its own sheet, in this one's place.
class UseSmileIDSampleCaptureAsStep extends ConsumerWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleCaptureAsStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from or is replaced on.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleIdDetails details = ref
        .watch(useSmileIDSampleFormsProvider)
        .idDetails;
    if (details.document == null) {
      return _UseSmileIDSampleClosing(scope: scope);
    }
    return UseSmileIDSamplePartialSheetBody(
      title: context.strings.captureAsTitle,
      testId: UseSmileIDSampleTestIds.captureAsSheet,
      child: UseSmileIDSampleCaptureAsSheet(
        selected: details.captureAsOverride,
        matched: useSmileIDSampleResolvedCaptureAs(
          details.document,
          null,
          details.genericDocument,
        ),
        onSelect: (UseSmileIDSampleCaptureAs? option) {
          if (option == UseSmileIDSampleCaptureAs.genericDocument) {
            unawaited(
              scope.navigator.go(
                UseSmileIDSampleStep.genericDocument.name,
                replace: scope.entry.id,
              ),
            );
            return;
          }
          ref.read(useSmileIDSampleFormsProvider.notifier).setCaptureAs(option);
          unawaited(scope.navigator.back());
        },
      ),
    );
  }
}

/// The generic document's builder, which keeps what it builds as the capture choice.
class UseSmileIDSampleGenericDocumentStep extends ConsumerWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleGenericDocumentStep({required this.scope, super.key});

  /// The sheet's entry, which Done goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      UseSmileIDSamplePartialSheetBody(
        title: context.strings.captureAsGenericDocument,
        testId: UseSmileIDSampleTestIds.genericDocumentSheet,
        child: UseSmileIDSampleGenericDocumentSheet(
          initial: ref
              .read(useSmileIDSampleFormsProvider)
              .idDetails
              .genericDocument,
          onDone: (UseSmileIDSampleGenericDocument genericDocument) {
            ref
                .read(useSmileIDSampleFormsProvider.notifier)
                .setGenericDocument(genericDocument);
            unawaited(scope.navigator.back());
          },
        ),
      );
}

/// A picker's content from the catalogue, the run's product and the form's details.
typedef _UseSmileIDSampleCatalogueBody =
    Widget Function(
      UseSmileIDSampleCatalogueStore catalogue,
      UseSmileIDSampleProduct? product,
      UseSmileIDSampleIdDetails details,
      UseSmileIDSampleFormsNotifier forms,
    );

/// A picker whose list may still be arriving, so it rebuilds as the store and the form change.
class _UseSmileIDSampleCatalogueSheet extends ConsumerStatefulWidget {
  const _UseSmileIDSampleCatalogueSheet({
    required this.scope,
    required this.testId,
    required this.body,
    this.needs,
  });

  final UseSmileIDSampleStepScope scope;

  final String testId;

  final _UseSmileIDSampleCatalogueBody body;

  /// What the form must already hold for this picker to open; without it the sheet closes.
  final bool Function(UseSmileIDSampleIdDetails details)? needs;

  @override
  ConsumerState<_UseSmileIDSampleCatalogueSheet> createState() =>
      _UseSmileIDSampleCatalogueSheetState();
}

class _UseSmileIDSampleCatalogueSheetState
    extends ConsumerState<_UseSmileIDSampleCatalogueSheet> {
  /// Read once: a sheet still animating out after its run leaves would find no product.
  late final UseSmileIDSampleProduct? _product = useSmileIDSampleProductOf(
    UseSmileIDSampleNavigationScope.engineOf(
      context,
    ).runProductId(widget.scope.entry),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        useSmileIDSampleEnsureCatalogue(ref, _product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleIdDetails details = ref
        .watch(useSmileIDSampleFormsProvider)
        .idDetails;
    if (!(widget.needs?.call(details) ?? true)) {
      return _UseSmileIDSampleClosing(scope: widget.scope);
    }
    final UseSmileIDSampleCatalogueStore catalogue = ref.read(
      useSmileIDSampleCatalogueStoreProvider,
    );
    return UseSmileIDSamplePartialSheetBody(
      testId: widget.testId,
      child: ListenableBuilder(
        listenable: catalogue,
        builder: (BuildContext _, Widget? _) => widget.body(
          catalogue,
          _product,
          details,
          ref.read(useSmileIDSampleFormsProvider.notifier),
        ),
      ),
    );
  }
}

/// A sheet the form isn't ready for: it draws nothing and goes back once, as a refused link did before.
class _UseSmileIDSampleClosing extends StatefulWidget {
  const _UseSmileIDSampleClosing({required this.scope});

  final UseSmileIDSampleStepScope scope;

  @override
  State<_UseSmileIDSampleClosing> createState() =>
      _UseSmileIDSampleClosingState();
}

class _UseSmileIDSampleClosingState extends State<_UseSmileIDSampleClosing> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(widget.scope.navigator.back()),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
