package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Immutable

/**
 * What the scanner is doing, said out loud on screen.
 *
 * A scan used to decode, unbind the camera and navigate in one frame, which reads as the preview
 * freezing for no reason: the work all happened, and none of it was acknowledged. Each state here
 * exists to be *shown* — found before linked, and a rejection that names itself and can be retried.
 */
@Immutable
sealed interface UseSmileIDSampleScanState {

    /** Camera live, nothing in hand. */
    data object Searching : UseSmileIDSampleScanState

    /** A code is in hand and being decoded. Brief, but it is the moment worth acknowledging. */
    data object Found : UseSmileIDSampleScanState

    /** Decoded, and held on screen long enough to be read before the screen leaves. */
    data class Linked(val handle: String, val remaining: String) : UseSmileIDSampleScanState

    /** Decoded into something that is not a session. The reason names a claim, never a value. */
    data class Rejected(val reason: String) : UseSmileIDSampleScanState
}
