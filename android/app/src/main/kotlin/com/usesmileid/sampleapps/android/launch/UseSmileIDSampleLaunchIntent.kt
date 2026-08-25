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
 * `probes` alone is also read off the launching URI: a deep link carries no extras, and half the flows
 * that assert on the card arrive that way. Only this one — letting a link seed the others contradicts R9.
 */
private fun Intent.probesFromLink(): Map<String, Any?> {
    val value = data?.takeIf { it.isHierarchical }?.getQueryParameter(UseSmileIDSampleLaunchArgs.PROBES)
    return if (value == null) emptyMap() else mapOf(UseSmileIDSampleLaunchArgs.PROBES to value)
}

/** `am start` picks the extra's type per flag, so the value is read without asserting one. */
@Suppress("DEPRECATION")
private fun Bundle.rawValue(name: String): Any? = get(name)
