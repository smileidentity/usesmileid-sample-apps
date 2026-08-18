package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/** A selection the bottom chrome is acting on: the count it reports and the action it offers. */
@Immutable
data class UseSmileIDSampleSelectionChrome(val count: Int, val onRemove: () -> Unit)

/**
 * What the bottom of the window shows. The nav bar is the default; a screen that takes the bottom
 * over — select mode is the only one — publishes its own bar here instead.
 *
 * The screen owns the state and the shell owns the slot, so the two bars cannot both be on screen
 * and the content inset does not change when one replaces the other.
 */
class UseSmileIDSampleChromeState {
    var selection: UseSmileIDSampleSelectionChrome? by mutableStateOf(null)
}

val LocalUseSmileIDSampleChrome = compositionLocalOf { UseSmileIDSampleChromeState() }
