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
) {
    var userDetails by mutableStateOf(userDetails)
        private set

    var idDetails by mutableStateOf(idDetails)
        private set

    var rememberDetails by mutableStateOf(rememberDetails)
        private set

    fun setUserField(field: UseSmileIDSampleUserField, value: String) {
        userDetails = field.write(userDetails, value)
    }

    fun rememberDetails(enabled: Boolean) {
        rememberDetails = enabled
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
                    // Looked up rather than valueOf: a restore after a release that renamed one of
                    // these would otherwise throw, and this state is restored after process death.
                    idDetails = UseSmileIDSampleIdDetails(
                        country = UseSmileIDSampleCountry.entries.firstOrNull { it.name == saved[4] },
                        idType = UseSmileIDSampleIdType.entries.firstOrNull { it.name == saved[5] },
                        idNumber = saved[6],
                    ),
                    rememberDetails = saved[7].toBoolean(),
                )
            },
        )
    }
}
