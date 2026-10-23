import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:usesmileid_njia/usesmileid_njia.dart';

/// What a step of `spec/njia-graph.json` shows: its `kind`, named as the graph names it.
enum UseSmileIDSampleStep {
  products,
  verifications,
  settings,
  licenses,
  captureMode,
  appearance,
  language,
  scenarioDrawer,
  verificationDetails,
  profileSwitch,
  profiles,
  newProfile,
  profileConfig,
  scanToken,
  countryPicker,
  idTypePicker,
  documentPicker,
  captureAs,
  genericDocument,
  consentDetailsForm,
  authUserId,
  idDetailsForm,
  sdkFlow,
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
