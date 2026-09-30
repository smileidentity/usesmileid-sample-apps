package com.usesmileid.sampleapps.android

import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleFlowTokens
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedBindings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenDecoder
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession

/** A fifteen-minute sandbox session binding nothing, which every run now needs before it reaches the SDK. */
internal fun testSession(
    nowMillis: Long = System.currentTimeMillis(),
    bindings: UseSmileIDSampleSimulatedBindings = UseSmileIDSampleSimulatedBindings(),
): UseSmileIDSampleTokenSession = requireNotNull(
    UseSmileIDSampleTokenDecoder.session(
        UseSmileIDSampleFlowTokens.session(
            span = UseSmileIDSampleSimulatedSpan.FifteenMinutes,
            bindings = bindings,
            environment = UseSmileIDSampleEnvironment.Sandbox,
            nowMillis = nowMillis,
        ),
    ),
)
