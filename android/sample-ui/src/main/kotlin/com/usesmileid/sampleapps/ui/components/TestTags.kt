package com.usesmileid.sampleapps.ui.components

import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag

/**
 * Attach an id only where the call site has one. Most `sample_*` ids are assigned to a primitive as
 * it appears on a given screen rather than to the primitive itself, so the screen supplies them.
 */
internal fun Modifier.tagged(testId: String?): Modifier = if (testId == null) this else testTag(testId)
