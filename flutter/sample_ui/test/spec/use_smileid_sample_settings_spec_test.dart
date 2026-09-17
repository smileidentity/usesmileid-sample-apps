import 'package:flutter_test/flutter_test.dart';
import 'package:sample_ui/sample_ui.dart';

import 'spec_file.dart';

void main() {
  late Map<String, Object?> settingsScreen;

  setUpAll(() {
    settingsScreen = objects(
      spec('screens.json')['screens'],
    ).firstWhere((Map<String, Object?> screen) => screen['id'] == 'settings');
  });

  test(
    'every id the screen spec names is attached somewhere in the package',
    () {
      final List<String> expected =
          (settingsScreen['testIds']! as List<Object?>).cast<String>();
      expect(expected, isNotEmpty, reason: 'extracted no ids');
      expect(
        expected.where(
          (String it) => !UseSmileIDSampleTestIds.all.contains(it),
        ),
        isEmpty,
      );
    },
  );

  test('the six switches are the ones the SDK mapping names', () {
    expect(
      UseSmileIDSampleSetting.values.map(
        (UseSmileIDSampleSetting it) => it.testId,
      ),
      <String>[
        'sample_setting_enhanced_smart_selfie',
        'sample_setting_agent_mode',
        'sample_setting_dark_mode',
        'sample_setting_consent_step',
        'sample_setting_instructions_step',
        'sample_setting_preview_step',
      ],
    );
  });

  test(
    'a fresh install shows the head-turn challenge on and agent mode off',
    () {
      // The spec's own default, and the state the design draws.
      const UseSmileIDSampleSettings plain = UseSmileIDSampleSettings();
      expect(plain.enhancedSmartSelfie, isTrue);
      expect(plain.agentMode, isFalse);
      expect(plain.consentStep, isTrue);
      expect(plain.instructionsStep, isTrue);
      expect(plain.previewStep, isTrue);
      expect(plain.darkMode, isFalse);
    },
  );

  test('turning either capture mode on turns the other off', () {
    // The SDK refuses the pair with BUILDER_AGENT_MODE_WITH_ENHANCED_LIVENESS at ERROR severity.
    const UseSmileIDSampleSettings plain = UseSmileIDSampleSettings();
    final UseSmileIDSampleSettings agent = plain.withSetting(
      UseSmileIDSampleSetting.agentMode,
      true,
    );
    expect(agent.agentMode, isTrue);
    expect(agent.enhancedSmartSelfie, isFalse);

    final UseSmileIDSampleSettings enhanced = agent.withSetting(
      UseSmileIDSampleSetting.enhancedSmartSelfie,
      true,
    );
    expect(enhanced.enhancedSmartSelfie, isTrue);
    expect(enhanced.agentMode, isFalse);
  });

  test('turning one off does not turn the other on', () {
    const UseSmileIDSampleSettings plain = UseSmileIDSampleSettings();
    final UseSmileIDSampleSettings neither = plain.withSetting(
      UseSmileIDSampleSetting.enhancedSmartSelfie,
      false,
    );
    expect(neither.enhancedSmartSelfie, isFalse);
    expect(neither.agentMode, isFalse);
  });

  test('a stored state carrying both is normalised rather than rejected', () {
    // A state saved before the mutex existed must load, not crash the app that saved it.
    const UseSmileIDSampleSettings both = UseSmileIDSampleSettings(
      enhancedSmartSelfie: true,
      agentMode: true,
    );
    expect(both.normalised().agentMode, isTrue);
    expect(both.normalised().enhancedSmartSelfie, isFalse);
  });

  test('normalising a legal state changes nothing', () {
    const UseSmileIDSampleSettings plain = UseSmileIDSampleSettings();
    expect(plain.normalised(), plain);
  });

  test('every switch is readable by its own row', () {
    const UseSmileIDSampleSettings plain = UseSmileIDSampleSettings();
    for (final UseSmileIDSampleSetting setting
        in UseSmileIDSampleSetting.values) {
      expect(plain[setting], isA<bool>());
    }
  });

  test('the navigation rows are the ones the design draws, in order', () {
    expect(
      useSmileIDSampleNavRows.map((UseSmileIDSampleNavRow it) => it.id),
      <String>['documentation', 'support', 'terms', 'privacy', 'licenses'],
    );
  });

  test('the links match the screen spec', () {
    final Map<String, Object?> links =
        settingsScreen['links']! as Map<String, Object?>;
    final Map<String, String?> ours = <String, String?>{
      for (final UseSmileIDSampleNavRow row in useSmileIDSampleNavRows)
        row.id: row.url,
    };
    expect(ours['documentation'], links['documentation']);
    expect(ours['support'], links['support']);
    expect(ours['terms'], links['terms']);
    expect(ours['privacy'], links['privacy']);
    // The notices ship in the binary, so this row has no url — Apache-2.0 §4.
    expect(ours['licenses'], isNull);
  });

  test('only the two legal pages leave the app', () {
    // Both serve their document as an embedded PDF, which a mobile browser shows as a stub.
    expect(
      useSmileIDSampleNavRows
          .where((UseSmileIDSampleNavRow it) => !it.opensInApp)
          .map((UseSmileIDSampleNavRow it) => it.id),
      <String>['terms', 'privacy'],
    );
  });

  test('the footer copy is the design wording the ruling settled', () {
    final Map<String, Object?> copy =
        settingsScreen['copy']! as Map<String, Object?>;
    // Brand copy, deliberately not the launcher label — see screens.json appNameCopy.
    expect(copy['footer'], 'Smile ID Sample App · 1.0.0');
  });
}
