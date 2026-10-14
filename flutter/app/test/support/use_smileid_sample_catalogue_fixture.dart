import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/catalogue/use_smileid_sample_catalogue_providers.dart';

/// The app's copy of spec/catalogue-fixture.json, which verify.sh keeps identical to it.
final String _fixture = File(
  'assets/catalogue-fixture.json',
).readAsStringSync();

/// A store over the fixture that decodes inline, so a fake-clock test settles.
UseSmileIDSampleCatalogueStore useSmileIDSampleFixtureStore() =>
    UseSmileIDSampleCatalogueStore(
      UseSmileIDSampleFixtureCatalogueSource(_fixture),
      decode: useSmileIDSampleDecodeInline,
    );

/// Points the app's catalogue at the fixture.
Override useSmileIDSampleFixtureCatalogueOverride() =>
    useSmileIDSampleCatalogueStoreProvider.overrideWith((Ref ref) {
      final UseSmileIDSampleCatalogueStore store =
          useSmileIDSampleFixtureStore();
      ref.onDispose(store.dispose);
      return store;
    });

/// Kenya, as the fixture names it.
const UseSmileIDSampleCountry kenya = UseSmileIDSampleCountry('KE', 'Kenya');

/// Kenya's National ID, as the rules derive it from the fixture.
const UseSmileIDSampleKycIdType kenyaNationalId = UseSmileIDSampleKycIdType(
  id: 'NATIONAL_ID',
  type: 'NATIONAL_ID',
  label: 'National ID',
  regex: r'^[0-9]{1,9}$',
);
