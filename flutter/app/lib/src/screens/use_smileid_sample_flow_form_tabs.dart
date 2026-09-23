import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_forms.dart';
import '../use_smileid_sample_journey.dart';
import '../use_smileid_sample_routes.dart';
import 'use_smileid_sample_above_shell_page.dart';

/// The details every product collects before its flow.
class UseSmileIDSampleUserDetailsTab extends ConsumerWidget {
  /// [productId] comes from the route and titles the page.
  const UseSmileIDSampleUserDetailsTab({required this.productId, super.key});

  /// The product whose flow this precedes.
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleProduct? product = _productFor(productId);
    final UseSmileIDSampleForms forms = ref.watch(
      useSmileIDSampleFormsProvider,
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
        onBack: back,
        onFieldChanged: ref
            .read(useSmileIDSampleFormsProvider.notifier)
            .setUserField,
        onContinue: () => context.push(
          product == null
              ? UseSmileIDSampleRoutes.sdkFlow(productId)
              : UseSmileIDSampleJourney.afterUserDetails(product),
        ),
        remember: forms.rememberDetails,
        onRememberChanged: ref
            .read(useSmileIDSampleFormsProvider.notifier)
            .setRemember,
      ),
    );
  }
}

/// Country, ID type and number, with both pickers as layers over it.
class UseSmileIDSampleKycFormTab extends ConsumerStatefulWidget {
  /// [openSheet] names a picker a deep link asked for, so the link opens this page with it up.
  const UseSmileIDSampleKycFormTab({
    required this.productId,
    this.openSheet,
    super.key,
  });

  /// The product whose flow this precedes.
  final String productId;

  /// Which picker to open on arrival, if any.
  final UseSmileIDSamplePicker? openSheet;

  @override
  ConsumerState<UseSmileIDSampleKycFormTab> createState() =>
      _UseSmileIDSampleKycFormTabState();
}

class _UseSmileIDSampleKycFormTabState
    extends ConsumerState<UseSmileIDSampleKycFormTab> {
  @override
  void initState() {
    super.initState();
    // After the first frame, because a sheet cannot be presented while this is still building —
    // and once only, so returning here later does not replay the link's sheet.
    final UseSmileIDSamplePicker? asked = widget.openSheet;
    if (asked != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          asked == UseSmileIDSamplePicker.country
              ? _pickCountry()
              : _pickIdType();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProduct? product = _productFor(widget.productId);
    final UseSmileIDSampleIdDetails details = ref
        .watch(useSmileIDSampleFormsProvider)
        .idDetails;
    void back() => useSmileIDSampleBack(
      context,
      UseSmileIDSampleRoutes.consentDetailsForm(widget.productId),
    );
    return UseSmileIDSampleAboveShellPage(
      onBack: back,
      child: UseSmileIDSampleKycFormScreen(
        title: product?.label ?? widget.productId,
        details: details,
        onBack: back,
        onPickCountry: _pickCountry,
        onPickIdType: _pickIdType,
        onIdNumberChanged: ref
            .read(useSmileIDSampleFormsProvider.notifier)
            .setIdNumber,
        // Through the journey, not straight to the route: the helper is the single place the
        // order lives, and a second copy is how two entry points come to disagree about it.
        onContinue: () => context.push(
          product == null
              ? UseSmileIDSampleRoutes.sdkFlow(widget.productId)
              : UseSmileIDSampleJourney.afterIdDetails(product),
        ),
        onScanToken: () {},
      ),
    );
  }

  Future<void> _pickCountry() => showUseSmileIDSampleSheet<void>(
    context: context,
    testId: UseSmileIDSampleTestIds.countrySheet,
    builder: (BuildContext sheetContext) => UseSmileIDSampleCountryPickerSheet(
      selected: ref.read(useSmileIDSampleFormsProvider).idDetails.country,
      onSelect: (UseSmileIDSampleCountry country) {
        ref.read(useSmileIDSampleFormsProvider.notifier).setCountry(country);
        Navigator.of(sheetContext).pop();
      },
    ),
  );

  Future<void> _pickIdType() => showUseSmileIDSampleSheet<void>(
    context: context,
    testId: UseSmileIDSampleTestIds.idTypeSheet,
    builder: (BuildContext sheetContext) => UseSmileIDSampleIdTypePickerSheet(
      country: ref.read(useSmileIDSampleFormsProvider).idDetails.country,
      selected: ref.read(useSmileIDSampleFormsProvider).idDetails.idType,
      onSelect: (UseSmileIDSampleIdType idType) {
        ref.read(useSmileIDSampleFormsProvider.notifier).setIdType(idType);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

/// Which picker a deep link asked for.
enum UseSmileIDSamplePicker {
  /// The country picker.
  country,

  /// The ID type picker.
  idType,
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
