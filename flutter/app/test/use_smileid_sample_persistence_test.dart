import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_jobs_repository.dart';
import 'package:usesmileid_sample_flutter/src/data/use_smileid_sample_preferences_settings_repository.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_providers.dart';
import 'package:usesmileid_sample_flutter/src/use_smileid_sample_routes.dart';

/// Settings survive a restart, which is the whole claim, so a restart is what the tests perform.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A fresh process: the store keeps its contents, and everything above it is built again.
  Future<UseSmileIDSamplePreferencesSettingsRepository> restart() async =>
      UseSmileIDSamplePreferencesSettingsRepository.open();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a first launch reads the plain defaults', () async {
    expect(
      await (await restart()).read(),
      equalsSettings(const UseSmileIDSampleSettings()),
    );
  });

  test('a switch survives the process that set it', () async {
    await (await restart()).setSetting(
      UseSmileIDSampleSetting.previewStep,
      false,
    );

    expect((await (await restart()).read()).previewStep, isFalse);
  });

  test('the store writes the keys the four apps share', () async {
    await (await restart()).setSetting(UseSmileIDSampleSetting.darkMode, true);

    final SharedPreferences raw = await SharedPreferences.getInstance();
    expect(raw.getBool(UseSmileIDSampleSettingsKeys.darkMode), isTrue);
    expect(
      raw.getKeys(),
      containsAll(<String>[
        UseSmileIDSampleSettingsKeys.enhancedSmartSelfie,
        UseSmileIDSampleSettingsKeys.agentMode,
        UseSmileIDSampleSettingsKeys.darkMode,
        UseSmileIDSampleSettingsKeys.consentStep,
        UseSmileIDSampleSettingsKeys.instructionsStep,
        UseSmileIDSampleSettingsKeys.previewStep,
      ]),
    );
  });

  // The mutex is the reason a write goes through the model rather than setting one key: turning
  // agent mode on has to turn enhanced liveness off, and BOTH have to reach the disk.
  test('turning on agent mode stores enhanced liveness off as well', () async {
    final UseSmileIDSamplePreferencesSettingsRepository store = await restart();
    expect((await store.read()).enhancedSmartSelfie, isTrue);

    await store.setSetting(UseSmileIDSampleSetting.agentMode, true);

    final UseSmileIDSampleSettings reread = await (await restart()).read();
    expect(reread.agentMode, isTrue);
    expect(reread.enhancedSmartSelfie, isFalse);
  });

  // A store written by an older build, or by hand, can hold the pair the SDK refuses. Normalising
  // only on the way in would hand that pair straight to the screen on the next launch.
  test('a stored pair the SDK refuses is dropped on the way out', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UseSmileIDSampleSettingsKeys.agentMode: true,
      UseSmileIDSampleSettingsKeys.enhancedSmartSelfie: true,
    });

    final UseSmileIDSampleSettings read = await (await restart()).read();
    expect(read.agentMode, isTrue);
    expect(read.enhancedSmartSelfie, isFalse);
  });

  testWidgets('the app opens in the appearance the store held', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      UseSmileIDSampleSettingsKeys.darkMode: true,
    });
    final UseSmileIDSamplePreferencesSettingsRepository store = await restart();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          useSmileIDSampleSettingsRepositoryProvider.overrideWithValue(store),
          useSmileIDSampleStoredSettingsProvider.overrideWithValue(
            await store.read(),
          ),
        ],
        child: MaterialApp.router(
          theme: UseSmileIDSampleTheme.light(),
          darkTheme: UseSmileIDSampleTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: useSmileIDSampleRouter(),
        ),
      ),
    );
    await tester.pump();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(useSmileIDSampleSettingsProvider).darkMode, isTrue);
  });

  testWidgets('the seeded profiles are reachable only through the argument', (
    WidgetTester tester,
  ) async {
    Future<UseSmileIDSampleProfiles> profilesFor(
      UseSmileIDSampleLaunchArgs args,
    ) async {
      final ProviderContainer container = ProviderContainer(
        overrides: [useSmileIDSampleLaunchArgsProvider.overrideWithValue(args)],
      );
      addTearDown(container.dispose);
      return container.read(useSmileIDSampleProfilesProvider);
    }

    expect(
      (await profilesFor(const UseSmileIDSampleLaunchArgs())).all,
      hasLength(1),
    );
    expect(
      (await profilesFor(
        const UseSmileIDSampleLaunchArgs(seedProfiles: true),
      )).all,
      hasLength(3),
    );
  });

  group('a stored verification this build cannot read', () {
    Future<List<UseSmileIDSampleJob>> readWith(String raw) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        useSmileIDSampleJobsKey: raw,
      });
      return await (await UseSmileIDSamplePreferencesJobsRepository.open())
              .read() ??
          const <UseSmileIDSampleJob>[];
    }

    String rowsOf(List<Object?> rows) => jsonEncode(rows);

    Map<String, Object?> rowAt(
      int hour, {
      String? id = 'job_1',
    }) => <String, Object?>{
      if (id case final String value) 'id': value,
      'userId': 'user_1',
      'product': 'smartSelfieEnrollment',
      'status': 'clear',
      'createdAtMillis': DateTime.utc(2026, 7, 16, hour).millisecondsSinceEpoch,
      'message': 'Approved',
      'httpStatus': 200,
    };

    // The whole reason the per-row skip exists: an erased history reads as "I have run nothing".
    test('does not take the rest of the history with it', () async {
      final List<UseSmileIDSampleJob> read = await readWith(
        rowsOf(<Object?>[rowAt(9, id: 'job_1'), null, rowAt(11, id: 'job_3')]),
      );

      expect(read.map((UseSmileIDSampleJob j) => j.id), <String>[
        'job_3',
        'job_1',
      ]);
    });

    // Substituted, not dropped: a field with a sensible default keeps the row addressable.
    test('substitutes a field an older write left in another shape', () async {
      final List<UseSmileIDSampleJob> read = await readWith(
        rowsOf(<Object?>[
          <String, Object?>{...rowAt(9), 'createdAtMillis': 'na'},
        ]),
      );

      expect(read.single.id, 'job_1');
      expect(read.single.createdAtMillis, 0);
    });

    test(
      'substitutes a product it no longer has, as Android and iOS do',
      () async {
        final List<UseSmileIDSampleJob> read = await readWith(
          rowsOf(<Object?>[
            <String, Object?>{...rowAt(9), 'product': 'somethingRemoved'},
          ]),
        );

        expect(read.single.product, UseSmileIDSampleProduct.values.first);
      },
    );

    test('substitutes a status it no longer has', () async {
      final List<UseSmileIDSampleJob> read = await readWith(
        rowsOf(<Object?>[
          <String, Object?>{...rowAt(9), 'status': 'somethingNew'},
        ]),
      );

      expect(read.single.status, UseSmileIDSampleStatus.processing);
    });

    // The one field with no substitute: everything else defaults, an unaddressable row cannot.
    test('drops a row with no id and keeps the rest', () async {
      final List<UseSmileIDSampleJob> read = await readWith(
        rowsOf(<Object?>[rowAt(9, id: null), rowAt(10, id: 'job_2')]),
      );

      expect(read.single.id, 'job_2');
    });

    test(
      'reads a store that is not JSON as empty rather than throwing',
      () async {
        expect(await readWith('not json'), isEmpty);
      },
    );

    // What proves the read change did not change the write: a round trip is still field for field.
    test('leaves the written shape alone', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final UseSmileIDSamplePreferencesJobsRepository store =
          await UseSmileIDSamplePreferencesJobsRepository.open();
      final UseSmileIDSampleJob written = UseSmileIDSampleJob(
        id: 'job_round_trip',
        userId: 'user_1',
        product: UseSmileIDSampleProduct.values.last,
        status: UseSmileIDSampleStatus.attention,
        createdAtMillis: DateTime.utc(2026, 7, 16, 12).millisecondsSinceEpoch,
        message: 'Provisional — needs review',
        httpStatus: 200,
        sandbox: false,
        sessionId: 'sess_1',
        partnerId: 'partner_1',
      );

      await store.add(written);
      final UseSmileIDSampleJob reread =
          (await (await UseSmileIDSamplePreferencesJobsRepository.open()).find(
            'job_round_trip',
          ))!;

      expect(reread.toJson(), written.toJson());
    });
  });
}

/// Compares two settings by their six switches, which is all a settings value is.
Matcher equalsSettings(UseSmileIDSampleSettings expected) =>
    predicate<UseSmileIDSampleSettings>(
      (UseSmileIDSampleSettings actual) => UseSmileIDSampleSetting.values.every(
        (UseSmileIDSampleSetting setting) =>
            actual[setting] == expected[setting],
      ),
      'the same six switches',
    );
