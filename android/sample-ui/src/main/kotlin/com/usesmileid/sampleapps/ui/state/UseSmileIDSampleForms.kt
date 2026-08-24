package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.setValue

/** What the two pre-flow forms hold. Saveable, because anything typed must survive the system killing the app behind the camera. */
class UseSmileIDSampleForms(
    userDetails: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    idDetails: UseSmileIDSampleIdDetails = UseSmileIDSampleIdDetails(),
    rememberDetails: Boolean = false,
    seededFrom: String? = null,
) {
    var userDetails by mutableStateOf(userDetails)
        private set

    var idDetails by mutableStateOf(idDetails)
        private set

    var rememberDetails by mutableStateOf(rememberDetails)
        private set

    /** The session handle whose claims seeded [idDetails], or null when the person owns those values. */
    var seededFrom: String? = seededFrom
        private set

    fun setUserField(field: UseSmileIDSampleUserField, value: String) {
        userDetails = field.write(userDetails, value)
    }

    fun rememberDetails(enabled: Boolean) {
        rememberDetails = enabled
    }

    /** Choosing a country clears the ID type, because the types it offered may not apply to the new one. */
    fun setCountry(country: UseSmileIDSampleCountry) {
        seededFrom = null
        idDetails = idDetails.copy(country = country, idType = null)
    }

    fun setIdType(idType: UseSmileIDSampleIdType) {
        seededFrom = null
        idDetails = idDetails.copy(idType = idType)
    }

    fun setIdNumber(value: String) {
        idDetails = idDetails.copy(idNumber = value)
    }

    /**
     * Seeds the ID form from a live token's plaintext claims, and never seeds the ID number, because
     * the token carries a vault reference rather than a value.
     *
     * [sessionId] is which session's claims these are — the session's display handle, never the
     * credential — and tracking it is what makes the seed correctable. Without it a seed from the
     * first token would block a relinked second token from fixing the form, so the screen would show
     * one country while the run submitted under another. Three rules follow, in order: a value the
     * person chose themselves outranks every token; a seed from a different session is replaced; and
     * a run with no live session clears a seed rather than letting it outlive its token.
     */
    fun prefillIdDetails(
        sessionId: String?,
        country: UseSmileIDSampleCountry?,
        idType: UseSmileIDSampleIdType?,
    ) {
        val seeded = seededFrom
        if (seeded == null && (idDetails.country != null || idDetails.idType != null)) return
        if (sessionId == null || country == null) {
            if (seeded != null) clearSeed()
            return
        }
        if (seeded == sessionId) return
        idDetails = idDetails.copy(country = country, idType = idType?.takeIf { country in it.countries })
        seededFrom = sessionId
    }

    private fun clearSeed() {
        seededFrom = null
        idDetails = idDetails.copy(country = null, idType = null)
    }

    companion object {
        val Saver: Saver<UseSmileIDSampleForms, Any> = listSaver(
            save = {
                listOf(
                    it.userDetails.firstName,
                    it.userDetails.lastName,
                    it.userDetails.email,
                    it.userDetails.phone,
                    it.idDetails.country?.name.orEmpty(),
                    it.idDetails.idType?.name.orEmpty(),
                    it.idDetails.idNumber,
                    it.rememberDetails.toString(),
                    it.seededFrom.orEmpty(),
                )
            },
            restore = { saved ->
                UseSmileIDSampleForms(
                    userDetails = UseSmileIDSampleUserDetails(
                        firstName = saved[0],
                        lastName = saved[1],
                        email = saved[2],
                        phone = saved[3],
                    ),
                    // Looked up rather than valueOf: this is restored after process death, where a rename would throw.
                    idDetails = UseSmileIDSampleIdDetails(
                        country = UseSmileIDSampleCountry.entries.firstOrNull { it.name == saved[4] },
                        idType = UseSmileIDSampleIdType.entries.firstOrNull { it.name == saved[5] },
                        idNumber = saved[6],
                    ),
                    rememberDetails = saved[7].toBoolean(),
                    // Restored so a rotation does not turn a seeded value into one the person owns.
                    seededFrom = saved.getOrNull(8)?.takeIf { it.isNotEmpty() },
                )
            },
        )
    }
}
