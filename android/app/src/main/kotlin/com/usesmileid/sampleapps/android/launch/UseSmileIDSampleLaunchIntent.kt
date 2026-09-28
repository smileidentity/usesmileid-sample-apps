package com.usesmileid.sampleapps.android.launch

import android.content.Intent
import android.os.Bundle
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs

/** Force-stop before sending: an intent to a live task rebuilds the Activity and resets these — see `docs/architecture.md` §4. */
internal fun Intent?.useSmileIDSampleLaunchArgs(): UseSmileIDSampleLaunchArgs {
    val intent = this ?: return UseSmileIDSampleLaunchArgs()
    val extras = intent.extras
    val raw = UseSmileIDSampleLaunchArgs.names.associateWith { name -> extras?.rawValue(name) }
    return UseSmileIDSampleLaunchArgs.from(raw + intent.argsFromLink())
}

/** Only `probes` and `catalogue` are read off a link, which carries no extras; the rest stay launch-only. */
private fun Intent.argsFromLink(): Map<String, Any?> {
    val link = data?.takeIf { it.isHierarchical } ?: return emptyMap()
    return LINK_ARGS.mapNotNull { name -> link.getQueryParameter(name)?.let { name to it } }.toMap()
}

private val LINK_ARGS = listOf(UseSmileIDSampleLaunchArgs.PROBES, UseSmileIDSampleLaunchArgs.CATALOGUE)

/** `am start` picks the extra's type per flag, so the value is read without asserting one. */
@Suppress("DEPRECATION")
private fun Bundle.rawValue(name: String): Any? = get(name)
