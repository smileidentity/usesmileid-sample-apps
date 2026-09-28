// Smile ID Design System — GENERATED. Do not edit by hand.
// Regenerate with: scripts/sync_design_tokens.py --all
//
// A stopgap: the upstream Compose emitter carries no durations. Names mirror the Dart emitter's
// SmileMotion. Delete this file once upstream emits them (spec/design-tokens.json
// motionMissingOnComposeAndSwiftUI).

package com.smileid.designsystem

import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

object SmileMotion {
    val durationFast: Duration = 200.milliseconds
    val durationNormal: Duration = 300.milliseconds
    val durationSlow: Duration = 350.milliseconds
    val motionTransition: Duration = 300.milliseconds
    val motionProgress: Duration = 350.milliseconds
    val skeletonDuration: Duration = 350.milliseconds
}
