package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable

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
