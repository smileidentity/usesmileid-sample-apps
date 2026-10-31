package com.usesmileid.sampleapps.android.launch

import android.content.Context
import android.content.Intent
import android.provider.Settings

/** A cold start from the launcher plays the intro; a link, an automation argument, a restored task or animations turned off go straight in. */
internal fun Intent?.playsLaunchIntro(restored: Boolean, animationsEnabled: Boolean): Boolean {
    val intent = this ?: return false
    if (restored || !animationsEnabled) return false
    if (intent.action != Intent.ACTION_MAIN || intent.categories?.contains(Intent.CATEGORY_LAUNCHER) != true) return false
    if (intent.data != null) return false
    // Launchers may add the platform's own `android.*` extras; anything else was put there by automation.
    return intent.extras?.keySet().orEmpty().all { it.startsWith(PLATFORM_EXTRA_PREFIX) }
}

/** Whether the system animates at all; the developer and accessibility settings both set the animator scale to zero to stop it. */
internal fun Context.animationsEnabled(): Boolean =
    Settings.Global.getFloat(contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) > 0f

private const val PLATFORM_EXTRA_PREFIX = "android."
