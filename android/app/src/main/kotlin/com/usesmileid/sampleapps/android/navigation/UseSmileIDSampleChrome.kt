package com.usesmileid.sampleapps.android.navigation

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** A selection the bottom chrome is acting on: the count it reports and the action it offers. */
@Immutable
data class UseSmileIDSampleSelectionChrome(val count: Int, val onRemove: () -> Unit)

/** What the bottom of the window shows. The screen owns the state, the shell owns the slot, so two bars cannot both appear. */
class UseSmileIDSampleChromeState {
    var selection: UseSmileIDSampleSelectionChrome? by mutableStateOf(null)

    /** Measured, not assumed: the bar floats over the content, so a screen must clear it itself. */
    var navBarHeight: Dp by mutableStateOf(0.dp)
}

val LocalUseSmileIDSampleChrome = compositionLocalOf { UseSmileIDSampleChromeState() }
