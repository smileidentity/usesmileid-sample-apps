package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList

/** One partner profile: who is signed in, and the defaults their jobs are seeded from. */
@Immutable
data class UseSmileIDSampleProfile(
    val id: String,
    val organisation: String,
    val person: String,
    val defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    /** Empty means the partner's portal default. */
    val callbackUrl: String = "",
) {
    /** The person's initials, as the design has them, falling back to the organisation for a new profile. */
    val initials: String
        get() = person.ifBlank { organisation }
            .split(" ").filter { it.isNotBlank() }.take(2)
            .joinToString("") { it.first().uppercase() }
            .ifEmpty { "?" }

    /** What a row says under the organisation: the person, or a placeholder until details are saved. */
    val caption: String
        get() = person.ifBlank { NO_USER_DETAILS_CAPTION }
}

/**
 * The profiles the app can act as, and which one is active. In memory until profiles are a real account concern.
 *
 * @param seed must not be empty; an empty list would otherwise surface far from here, as the products
 * screen throwing on its first read of the active profile.
 */
class UseSmileIDSampleProfiles(seed: List<UseSmileIDSampleProfile> = starter()) {

    init {
        require(seed.isNotEmpty()) { "UseSmileIDSampleProfiles needs at least one profile" }
    }

    private val items = seed.toMutableStateList()

    var activeId by mutableStateOf(seed.first().id)
        private set

    /** The last profile [add] created, until whoever confirmed it calls [clearLastCreated]. */
    var lastCreatedId: String? by mutableStateOf(null)
        private set

    val all: List<UseSmileIDSampleProfile> get() = items

    val active: UseSmileIDSampleProfile get() = items.firstOrNull { it.id == activeId } ?: items.first()

    /** Position in the list, which is what picks a profile's avatar hue. */
    val activeIndex: Int get() = items.indexOfFirst { it.id == activeId }.coerceAtLeast(0)

    fun setActive(id: String) {
        if (items.any { it.id == id }) activeId = id
    }

    fun clearLastCreated() {
        lastCreatedId = null
    }

    fun find(id: String) = items.firstOrNull { it.id == id }

    fun add(
        organisation: String,
        person: String,
        defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    ): UseSmileIDSampleProfile {
        // First free id, not one derived from the count: duplicate keys crash the list and double a test id.
        val id = generateSequence(items.size + 1) { it + 1 }
            .map { "p-$it" }
            .first { candidate -> items.none { it.id == candidate } }
        val profile = UseSmileIDSampleProfile(
            id = id,
            organisation = organisation,
            person = person,
            defaults = defaults,
        )
        items.add(profile)
        lastCreatedId = id
        return profile
    }

    /** A null [callbackUrl] leaves the stored one alone; only a caller that edited it passes a value. */
    fun setDefaults(id: String, defaults: UseSmileIDSampleUserDetails, callbackUrl: String? = null) {
        val index = items.indexOfFirst { it.id == id }
        if (index < 0) return
        val current = items[index]
        // The starter names nobody until its details are saved; a created profile keeps the name its sheet gave it.
        val person = current.person.ifBlank { "${defaults.firstName} ${defaults.lastName}".trim() }
        items[index] = current.copy(defaults = defaults, person = person, callbackUrl = callbackUrl ?: current.callbackUrl)
    }

    companion object {
        /** The fixtures only when `seedProfiles` asks, so the shell holds no choice a unit test cannot reach. */
        fun forLaunch(args: UseSmileIDSampleLaunchArgs) =
            UseSmileIDSampleProfiles(if (args.seedProfiles) fixtures() else starter())

        /** A plain launch: one empty profile, never [fixtures] — the active organisation names the partner on the SDK's consent screen. */
        fun starter() = listOf(
            UseSmileIDSampleProfile(id = "p-1", organisation = STARTER_ORGANISATION, person = ""),
        )

        /** The three the design's sheet shows. Reached only by the `seedProfiles` launch argument — see `spec/launch-args.json`. */
        fun fixtures() = listOf(
            UseSmileIDSampleProfile(
                id = "p-1",
                organisation = "UpTech Finance",
                person = "Kwame Asante",
                defaults = UseSmileIDSampleUserDetails(firstName = "Kwame", lastName = "Asante"),
            ),
            UseSmileIDSampleProfile(
                id = "p-2",
                organisation = "Kazi Microlending",
                person = "Amina Diallo",
                defaults = UseSmileIDSampleUserDetails(firstName = "Amina", lastName = "Diallo"),
            ),
            UseSmileIDSampleProfile(
                id = "p-3",
                organisation = "PesaLink",
                person = "Tunde Okafor",
                defaults = UseSmileIDSampleUserDetails(firstName = "Tunde", lastName = "Okafor"),
            ),
        )

        /** Shown on the consent screen as the partner until a profile is created, so it must read as a placeholder. */
        const val STARTER_ORGANISATION = "Default profile"
    }
}

private const val NO_USER_DETAILS_CAPTION = "No user details yet"
