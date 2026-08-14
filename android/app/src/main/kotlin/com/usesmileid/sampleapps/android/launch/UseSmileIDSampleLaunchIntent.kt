package com.usesmileid.sampleapps.android.launch

import android.content.Intent
import android.os.Bundle
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs

/**
 * Android's delivery mechanism for the canonical launch arguments: intent extras.
 *
 * ```
 * adb shell am start -e scenario expiredToken -e route shell -e autostart biometricKyc
 * ```
 *
 * Force-stop the app first, and reach the screen you want to assert on by tapping. An intent sent to
 * a live task carries `FLAG_ACTIVITY_NEW_TASK`, which rebuilds the Activity around the new intent —
 * so a deep link sent mid-run silently resets these to their defaults rather than keeping them.
 * Measured on a device; the reasoning is under R9 in `docs/plan/navigation-plan.md`.
 */
internal fun Intent?.useSmileIDSampleLaunchArgs(): UseSmileIDSampleLaunchArgs {
    val extras = this?.extras ?: return UseSmileIDSampleLaunchArgs()
    return UseSmileIDSampleLaunchArgs.from(UseSmileIDSampleLaunchArgs.names.associateWith(extras::rawValue))
}

/** `am start` picks the extra's type per flag, so the value is read without asserting one. */
@Suppress("DEPRECATION")
private fun Bundle.rawValue(name: String): Any? = get(name)
