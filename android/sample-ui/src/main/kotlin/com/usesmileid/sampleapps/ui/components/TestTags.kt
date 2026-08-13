package com.usesmileid.sampleapps.ui.components

import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag

/** Most `sample_*` ids are assigned per screen rather than per primitive, so the screen supplies them. */
internal fun Modifier.tagged(testId: String?): Modifier = if (testId == null) this else testTag(testId)
