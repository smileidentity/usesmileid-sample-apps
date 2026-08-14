package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver

/** The fields the design labels "attached to every job", which is why every product collects them. */
@Immutable
data class UseSmileIDSampleUserDetails(
    val firstName: String = "",
    val lastName: String = "",
    val email: String = "",
    val phone: String = "",
) {
    /** The design's own rule: "First and last name are required." */
    val isComplete: Boolean get() = firstName.isNotBlank() && lastName.isNotBlank()

    companion object {
        val Saver: Saver<MutableState<UseSmileIDSampleUserDetails>, Any> = listSaver(
            save = { listOf(it.value.firstName, it.value.lastName, it.value.email, it.value.phone) },
            restore = { mutableStateOf(UseSmileIDSampleUserDetails(it[0], it[1], it[2], it[3])) },
        )
    }
}

/** Which user-details row changed, so the form reports one callback rather than four. */
enum class UseSmileIDSampleUserField(val id: String, val label: String, val placeholder: String, val required: Boolean) {
    FirstName("firstName", "First name", "Add first name", required = true),
    LastName("lastName", "Last name", "Add last name", required = true),
    Email("email", "Email (optional)", "name@company.com", required = false),
    Phone("phone", "Phone (optional)", "+254 700 000 000", required = false),
    ;

    fun read(details: UseSmileIDSampleUserDetails) = when (this) {
        FirstName -> details.firstName
        LastName -> details.lastName
        Email -> details.email
        Phone -> details.phone
    }

    fun write(details: UseSmileIDSampleUserDetails, value: String) = when (this) {
        FirstName -> details.copy(firstName = value)
        LastName -> details.copy(lastName = value)
        Email -> details.copy(email = value)
        Phone -> details.copy(phone = value)
    }
}

/** The ID-details form. ID type stays unselectable until a country is chosen, which the form is built around. */
@Immutable
data class UseSmileIDSampleIdDetails(
    val country: UseSmileIDSampleCountry? = null,
    val idType: UseSmileIDSampleIdType? = null,
    val idNumber: String = "",
) {
    val isComplete: Boolean get() = country != null && idType != null && idNumber.isNotBlank()
}

/** A country the sandbox supports, with the flag the picker leads each row with. */
enum class UseSmileIDSampleCountry(val code: String, val label: String, val flag: String) {
    Nigeria("NG", "Nigeria", "🇳🇬"),
    Kenya("KE", "Kenya", "🇰🇪"),
    Ghana("GH", "Ghana", "🇬🇭"),
    SouthAfrica("ZA", "South Africa", "🇿🇦"),
    Uganda("UG", "Uganda", "🇺🇬"),
    Tanzania("TZ", "Tanzania", "🇹🇿"),
    Rwanda("RW", "Rwanda", "🇷🇼"),
}

/** ID types, filtered by country, which is why the trigger is disabled until one is chosen. */
enum class UseSmileIDSampleIdType(val id: String, val label: String, val countries: Set<UseSmileIDSampleCountry>) {
    NationalId("NATIONAL_ID", "National ID", UseSmileIDSampleCountry.entries.toSet()),
    Passport("PASSPORT", "Passport", UseSmileIDSampleCountry.entries.toSet()),
    DriversLicense("DRIVERS_LICENSE", "Driver's licence", setOf(UseSmileIDSampleCountry.Nigeria, UseSmileIDSampleCountry.Kenya, UseSmileIDSampleCountry.SouthAfrica)),
    VoterId("VOTER_ID", "Voter ID", setOf(UseSmileIDSampleCountry.Nigeria, UseSmileIDSampleCountry.Ghana)),
    ;

    companion object {
        fun of(country: UseSmileIDSampleCountry?) = entries.filter { country != null && country in it.countries }
    }
}
