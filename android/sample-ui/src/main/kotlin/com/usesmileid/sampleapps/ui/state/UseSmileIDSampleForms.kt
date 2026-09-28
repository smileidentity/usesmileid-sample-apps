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

    /** Choosing a country clears the ID type and document, which may not apply to it, and keeps the typed number. */
    fun setCountry(country: UseSmileIDSampleCountry) {
        idDetails = idDetails.copy(country = country, idType = null, document = null)
    }

    fun setIdType(idType: UseSmileIDSampleKycIdType) {
        idDetails = idDetails.copy(idType = idType)
    }

    fun setDocument(document: UseSmileIDSampleDocument) {
        idDetails = idDetails.copy(document = document)
    }

    fun setCaptureAs(captureAs: UseSmileIDSampleCaptureAs) {
        idDetails = idDetails.copy(captureAs = captureAs)
    }

    fun setCustomDocument(custom: UseSmileIDSampleCustomDocument) {
        idDetails = idDetails.copy(custom = custom, captureAs = UseSmileIDSampleCaptureAs.Custom)
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
                val id = it.idDetails
                listOf(
                    it.userDetails.firstName,
                    it.userDetails.lastName,
                    it.userDetails.email,
                    it.userDetails.phone,
                    it.saveToProfile.toString(),
                    it.organisation,
                    id.idNumber,
                    id.country?.code.orEmpty(),
                    id.country?.name.orEmpty(),
                    id.idType?.let { t -> listOf(t.id, t.type, t.label, t.regex).joinToString(FIELD) }.orEmpty(),
                    id.document?.let { d ->
                        listOf(d.code, d.subType.orEmpty(), d.name, d.hasBack.toString(), d.format.toString()).joinToString(FIELD)
                    }.orEmpty(),
                    id.captureAs.name,
                    with(id.custom) { listOf(displayName, hasBackSide.toString(), orientation.name, aspectRatio.name).joinToString(FIELD) },
                )
            },
            restore = { saved ->
                val at = { index: Int -> saved.getOrNull(index).orEmpty() }
                val parts = { index: Int -> at(index).split(FIELD) }
                UseSmileIDSampleForms(
                    userDetails = UseSmileIDSampleUserDetails(
                        firstName = at(0),
                        lastName = at(1),
                        email = at(2),
                        phone = at(3),
                    ),
                    saveToProfile = at(4) != "false",
                    organisation = at(5),
                    // Whole rows, looked up by name rather than valueOf: a rename must not throw after process death.
                    idDetails = UseSmileIDSampleIdDetails(
                        idNumber = at(6),
                        country = at(7).takeIf { it.isNotEmpty() }?.let { UseSmileIDSampleCountry(it, at(8)) },
                        idType = parts(9).takeIf { it.size == 4 }?.let { (id, type, label, regex) ->
                            UseSmileIDSampleKycIdType(id, type, label, regex)
                        },
                        document = parts(10).takeIf { it.size == 5 }?.let { (code, subType, name, hasBack, format) ->
                            UseSmileIDSampleDocument(code, subType.ifEmpty { null }, name, hasBack == "true", format.toIntOrNull() ?: 1)
                        },
                        captureAs = UseSmileIDSampleCaptureAs.entries.firstOrNull { it.name == at(11) }
                            ?: UseSmileIDSampleCaptureAs.Automatic,
                        custom = parts(12).takeIf { it.size == 4 }?.let { (name, back, orientation, ratio) ->
                            UseSmileIDSampleCustomDocument(
                                displayName = name,
                                hasBackSide = back != "false",
                                orientation = UseSmileIDSampleDocumentOrientation.entries.firstOrNull { it.name == orientation }
                                    ?: UseSmileIDSampleDocumentOrientation.Landscape,
                                aspectRatio = UseSmileIDSampleAspectRatio.entries.firstOrNull { it.name == ratio }
                                    ?: UseSmileIDSampleAspectRatio.Off,
                            )
                        } ?: UseSmileIDSampleCustomDocument(),
                    ),
                )
            },
        )

        // A unit separator, which no API label, regex or typed name contains.
        private const val FIELD = "\u001F"
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
