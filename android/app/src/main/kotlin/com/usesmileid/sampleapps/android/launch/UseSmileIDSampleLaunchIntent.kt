package com.usesmileid.sampleapps.android.launch

import android.content.Intent
import android.os.Bundle
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleLaunchArgs

/**
 * Intent extras: `adb shell am start -e scenario expiredToken -e route shell`.
 *
 * Force-stop first, and reach the screen you assert on by tapping — an intent sent to a live task
 * rebuilds the Activity and resets these. See R9 in `docs/plan/navigation-plan.md`.
 */
internal fun Intent?.useSmileIDSampleLaunchArgs(): UseSmileIDSampleLaunchArgs {
    val extras = this?.extras ?: return UseSmileIDSampleLaunchArgs()
    return UseSmileIDSampleLaunchArgs.from(UseSmileIDSampleLaunchArgs.names.associateWith(extras::rawValue))
}

/** `am start` picks the extra's type per flag, so the value is read without asserting one. */
@Suppress("DEPRECATION")
private fun Bundle.rawValue(name: String): Any? = get(name)
