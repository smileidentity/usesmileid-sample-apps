import { decodeGraph, njiaCodec, wireOfStrings, type NjiaCodec, type NjiaGraph } from '@smileid/njia';

// A copy of spec/njia-graph.json: Metro cannot reach spec/, and verify.sh fails if the copy drifts.
import graphJson from '../../assets/njia-graph.json';

/// What a step of `spec/njia-graph.json` shows: its `kind`, named as the graph names it.
export const smileIDSampleSteps = [
  /// The products grid, where the app starts.
  'products',
  /// The verifications list.
  'verifications',
  /// The settings tab.
  'settings',
  /// The third-party notices, inside settings.
  'licenses',
  /// The capture-mode sheet over settings.
  'captureMode',
  'submission',
  /// The appearance sheet over settings.
  'appearance',
  /// The language sheet over settings.
  'language',
  /// The scenario drawer over settings.
  'scenarioDrawer',
  /// One verification's details.
  'verificationDetails',
  /// The profile-switch sheet.
  'profileSwitch',
  /// The profiles list.
  'profiles',
  /// The new-profile sheet over the profiles list.
  'newProfile',
  /// One profile's own page.
  'profileConfig',
  /// The token scanner.
  'scanToken',
  /// The country picker over the ID-details form.
  'countryPicker',
  /// The ID type picker over the ID-details form.
  'idTypePicker',
  /// The document picker over the ID-details form.
  'documentPicker',
  /// The capture-as sheet over the ID-details form.
  'captureAs',
  /// The generic-document sheet over the ID-details form.
  'genericDocument',
  /// The details every product collects before its flow.
  'consentDetailsForm',
  /// SmartSelfie Authentication's user ID.
  'authUserId',
  /// The ID-details form.
  'idDetailsForm',
  /// The SDK flow inside the shell.
  'sdkFlow',
  /// The SDK flow over the whole shell.
  'sdkFlowFullScreen',
] as const;

export type UseSmileIDSampleStep = (typeof smileIDSampleSteps)[number];

/// What a run's product, token and launch say about it: the facts the graph's `skipWhen` reads.
export const smileIDSampleFacts = [
  /// SmartSelfie Authentication, which asks for the user ID to authenticate.
  'needsUserId',
  /// A product that needs ID details the token doesn't already bind.
  'needsIdDetails',
  /// The run was launched full screen, over the tab bar.
  'fullScreenRun',
] as const;

export type UseSmileIDSampleFact = (typeof smileIDSampleFacts)[number];

/// The app's graph, read with its own kinds and facts.
export type UseSmileIDSampleGraph = NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact>;

/// Reads the graph with the app's own kinds and facts, so one the app doesn't know fails to decode.
export const smileIDSampleNjiaCodec: NjiaCodec<UseSmileIDSampleStep, UseSmileIDSampleFact> = njiaCodec(
  wireOfStrings(smileIDSampleSteps),
  wireOfStrings(smileIDSampleFacts),
);

/// The four apps' one navigation graph, as this build bundles it, back to text for njia's strict reader.
export const smileIDSampleNjiaGraph = (json: unknown = graphJson): UseSmileIDSampleGraph =>
  decodeGraph(smileIDSampleNjiaCodec, JSON.stringify(json));
