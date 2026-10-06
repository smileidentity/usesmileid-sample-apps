import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart'
    show useSmileIDSampleUseSandbox;
import 'use_smileid_sample_http_catalogue_source.dart';

/// The ID form's lists for the current run; the `catalogue` launch argument picks where they come from.
final Provider<UseSmileIDSampleCatalogueStore>
useSmileIDSampleCatalogueStoreProvider =
    Provider<UseSmileIDSampleCatalogueStore>((Ref ref) {
      final UseSmileIDSampleCatalogueStore store =
          UseSmileIDSampleCatalogueStore(
            useSmileIDSampleCatalogueSource(
              ref.watch(useSmileIDSampleLaunchArgsProvider).catalogue,
            ),
          );
      ref.onDispose(store.dispose);
      return store;
    });

/// Where the catalogue asks: the session's environment, as status refresh chooses it.
UseSmileIDSampleEnvironment useSmileIDSampleCatalogueEnvironment(
  UseSmileIDSampleTokenSession? live,
) => useSmileIDSampleUseSandbox(live)
    ? UseSmileIDSampleEnvironment.sandbox
    : UseSmileIDSampleEnvironment.production;

/// Enhanced Document Verification's own list, which [live]'s token decides; any other product has none.
void useSmileIDSampleEnsureEnabled(
  UseSmileIDSampleCatalogueStore store,
  UseSmileIDSampleProduct? product,
  UseSmileIDSampleTokenSession? live,
) {
  if (product == UseSmileIDSampleProduct.enhancedDocumentVerification) {
    store.ensureEnabled(
      useSmileIDSampleCatalogueEnvironment(live),
      useSmileIDSampleCatalogueLocale(),
      live,
    );
  }
}

/// The language the app is pinned to, by `appLocale` or the Language setting; null follows the device.
String? useSmileIDSampleCatalogueLanguage;

/// The API translates document and country names; an unsupported locale comes back in English.
String useSmileIDSampleCatalogueLocale() =>
    useSmileIDSampleCatalogueLanguage ??
    WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag();
