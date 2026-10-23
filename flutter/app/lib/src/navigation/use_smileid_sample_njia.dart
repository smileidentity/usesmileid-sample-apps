import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:usesmileid_njia/usesmileid_njia.dart';

/// What a step of `spec/njia-graph.json` shows: its `kind`, named as the graph names it.
enum UseSmileIDSampleStep {
  /// The products grid, where the app starts.
  products,

  /// The verifications list.
  verifications,

  /// The settings tab.
  settings,

  /// The third-party notices, inside settings.
  licenses,

  /// The capture-mode sheet over settings.
  captureMode,

  /// The appearance sheet over settings.
  appearance,

  /// The language sheet over settings.
  language,

  /// The scenario drawer over settings.
  scenarioDrawer,

  /// One verification's details.
  verificationDetails,

  /// The profile-switch sheet.
  profileSwitch,

  /// The profiles list.
  profiles,

  /// The new-profile sheet over the profiles list.
  newProfile,

  /// One profile's own page.
  profileConfig,

  /// The token scanner.
  scanToken,

  /// The country picker over the ID-details form.
  countryPicker,

  /// The ID type picker over the ID-details form.
  idTypePicker,

  /// The document picker over the ID-details form.
  documentPicker,

  /// The capture-as sheet over the ID-details form.
  captureAs,

  /// The generic-document sheet over the ID-details form.
  genericDocument,

  /// The details every product collects before its flow.
  consentDetailsForm,

  /// SmartSelfie Authentication's user ID.
  authUserId,

  /// The ID-details form.
  idDetailsForm,

  /// The SDK flow inside the shell.
  sdkFlow,

  /// The SDK flow over the whole shell.
  sdkFlowFullScreen,
}

/// What a run's product, token and launch say about it: the facts the graph's `skipWhen` reads.
enum UseSmileIDSampleFact {
  /// SmartSelfie Authentication, which asks for the user ID to authenticate.
  needsUserId,

  /// A product that needs ID details the token doesn't already bind.
  needsIdDetails,

  /// The run was launched full screen, over the tab bar.
  fullScreenRun,
}

/// The app's graph, read with its own kinds and facts.
typedef UseSmileIDSampleGraph =
    NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact>;

/// Reads the graph with the app's own kinds and facts, so one the app doesn't know fails to decode.
final NjiaCodec<UseSmileIDSampleStep, UseSmileIDSampleFact>
useSmileIDSampleNjiaCodec = NjiaCodec(
  kinds: NjiaWire.ofEnum(UseSmileIDSampleStep.values),
  facts: NjiaWire.ofEnum(UseSmileIDSampleFact.values),
);

/// The bundled copy of `spec/njia-graph.json`, which `scripts/sync_spec_assets.py` keeps byte-identical.
const String useSmileIDSampleNjiaGraphAsset = 'assets/njia-graph.json';

/// The four apps' one navigation graph, as this build bundles it.
Future<UseSmileIDSampleGraph> useSmileIDSampleNjiaGraph([
  AssetBundle? bundle,
]) async => useSmileIDSampleNjiaCodec.decodeGraph(
  await (bundle ?? rootBundle).loadString(useSmileIDSampleNjiaGraphAsset),
);
