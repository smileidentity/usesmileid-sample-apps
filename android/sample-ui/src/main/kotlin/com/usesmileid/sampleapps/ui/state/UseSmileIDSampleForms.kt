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
    saveToProfile: Boolean = true,
    organisation: String = "",
) {
    var userDetails by mutableStateOf(userDetails)
        private set

    var idDetails by mutableStateOf(idDetails)
        private set

    /** Whether Continue keeps what was typed: into the active profile, or as a new one when there is none. */
    var saveToProfile by mutableStateOf(saveToProfile)
        private set

    /** The new profile's name, asked only while there is no profile. */
    var organisation by mutableStateOf(organisation)
        private set

    fun setUserField(field: UseSmileIDSampleUserField, value: String) {
        userDetails = field.write(userDetails, value)
    }

    fun saveToProfile(enabled: Boolean) {
        saveToProfile = enabled
    }

    fun organisation(value: String) {
        organisation = value
    }

    /** A run starts from the profile it runs as; whatever was typed for another is dropped. */
    fun fillFrom(profile: UseSmileIDSampleProfile?) {
        userDetails = profile?.defaults ?: UseSmileIDSampleUserDetails()
        organisation = ""
        saveToProfile = true
    }

    /** A product tap: fills from the active profile, and never carries the last run's ID details into this one. */
    fun startRun(profile: UseSmileIDSampleProfile?) {
        profile?.let(::fillFrom)
        idDetails = UseSmileIDSampleIdDetails()
    }

    /** Choosing a country clears the ID type, because the types it offered may not apply to the new one. */
    fun setCountry(country: UseSmileIDSampleCountry) {
        idDetails = idDetails.copy(country = country, idType = null)
    }

    fun setIdType(idType: UseSmileIDSampleIdType) {
        idDetails = idDetails.copy(idType = idType)
    }

    fun setIdNumber(value: String) {
        idDetails = idDetails.copy(idNumber = value)
    }

    /** Sign out: what a partner would expect gone. */
    fun clear() {
        fillFrom(null)
        idDetails = UseSmileIDSampleIdDetails()
    }

    companion object {
        val Saver: Saver<UseSmileIDSampleForms, Any> = listSaver<UseSmileIDSampleForms, String>(
            save = {
                listOf(
                    it.userDetails.firstName,
                    it.userDetails.lastName,
                    it.userDetails.email,
                    it.userDetails.phone,
                    it.idDetails.country?.name.orEmpty(),
                    it.idDetails.idType?.name.orEmpty(),
                    it.idDetails.idNumber,
                    it.saveToProfile.toString(),
                    it.organisation,
                )
            },
            restore = { saved ->
                val at = { index: Int -> saved.getOrNull(index).orEmpty() }
                UseSmileIDSampleForms(
                    userDetails = UseSmileIDSampleUserDetails(
                        firstName = at(0),
                        lastName = at(1),
                        email = at(2),
                        phone = at(3),
                    ),
                    // Looked up rather than valueOf: this is restored after process death, where a rename would throw.
                    idDetails = UseSmileIDSampleIdDetails(
                        country = UseSmileIDSampleCountry.entries.firstOrNull { it.name == at(4) },
                        idType = UseSmileIDSampleIdType.entries.firstOrNull { it.name == at(5) },
                        idNumber = at(6),
                    ),
                    saveToProfile = at(7) != "false",
                    organisation = at(8),
                )
            },
        )
    }
}

/** Continue's write-back to the active profile, or a new one; token-supplied fields are never stored. */
fun UseSmileIDSampleProfiles.keep(
    forms: UseSmileIDSampleForms,
    requirement: UseSmileIDSampleUserDetailsRequirement = UseSmileIDSampleUserDetailsRequirement(),
) {
    if (!forms.saveToProfile) return
    val current = active
    val kept = UseSmileIDSampleUserField.entries.fold(current?.defaults ?: UseSmileIDSampleUserDetails()) { details, field ->
        if (requirement.supplies(field)) details else field.write(details, field.read(forms.userDetails))
    }
    if (current != null) {
        update(current.id, defaults = kept)
    } else {
        add(organisation = forms.organisation, defaults = kept, activate = true)
    }
}
