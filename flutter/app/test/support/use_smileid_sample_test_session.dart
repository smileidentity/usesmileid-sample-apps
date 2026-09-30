import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid_sample_flutter/src/flow/use_smileid_sample_flow_tokens.dart';
import 'package:usesmileid_sample_flutter/src/state/use_smileid_sample_session_providers.dart';

/// A fifteen-minute sandbox session binding nothing, which every run needs before it reaches the SDK.
UseSmileIDSampleTokenSession useSmileIDSampleTestSession({int? nowMillis}) =>
    UseSmileIDSampleTokenDecoder.session(
      UseSmileIDSampleFlowTokens.session(
        span: UseSmileIDSampleSimulatedSpan.fifteenMinutes,
        bindings: const UseSmileIDSampleSimulatedBindings(),
        environment: UseSmileIDSampleEnvironment.sandbox,
        nowMillis: nowMillis ?? DateTime.now().millisecondsSinceEpoch,
      ),
    )!;

/// Starts the app with a live session, so a product tap opens its form rather than the scanner.
List<Override> useSmileIDSampleLinkedSessionOverrides() {
  final UseSmileIDSampleSessionRecord stored = UseSmileIDSampleSessionRecord(
    live: useSmileIDSampleTestSession(),
  );
  return <Override>[
    useSmileIDSampleSessionRepositoryProvider.overrideWithValue(
      UseSmileIDSampleMemorySessionRepository(stored),
    ),
    useSmileIDSampleStoredSessionProvider.overrideWithValue(stored),
  ];
}
