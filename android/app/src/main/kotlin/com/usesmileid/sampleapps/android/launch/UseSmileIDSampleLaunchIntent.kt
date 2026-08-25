package com.usesmileid.sampleapps.android.launch

import android.content.Intent
import android.os.Bundle
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs

/** Force-stop before sending: an intent to a live task rebuilds the Activity and resets these — R9 in `docs/plan/navigation-plan.md`. */
internal fun Intent?.useSmileIDSampleLaunchArgs(): UseSmileIDSampleLaunchArgs {
    val intent = this ?: return UseSmileIDSampleLaunchArgs()
    val extras = intent.extras
    val raw = UseSmileIDSampleLaunchArgs.names.associateWith { name -> extras?.rawValue(name) }
    return UseSmileIDSampleLaunchArgs.from(raw + intent.probesFromLink())
}

/**
 * `probes` alone is also read off the launching URI. A deep link arrives as an ACTION_VIEW intent
 * with no extras, and half the flows that assert on the result card arrive that way — on release the
 * card would be hidden and those runs could only ever pass on debug. Only this argument: letting a
 * link seed the others would contradict R9, which is that a deep link resets them.
 */
private fun Intent.probesFromLink(): Map<String, Any?> {
    val value = data?.takeIf { it.isHierarchical }?.getQueryParameter(UseSmileIDSampleLaunchArgs.PROBES)
    return if (value == null) emptyMap() else mapOf(UseSmileIDSampleLaunchArgs.PROBES to value)
}

/** `am start` picks the extra's type per flag, so the value is read without asserting one. */
@Suppress("DEPRECATION")
private fun Bundle.rawValue(name: String): Any? = get(name)
