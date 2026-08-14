package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleEnvironment

/** One partner profile: who is signed in, which environment, and the defaults their jobs are seeded from. */
@Immutable
data class UseSmileIDSampleProfile(
    val id: String,
    val organisation: String,
    val person: String,
    val environment: UseSmileIDSampleEnvironment,
    val defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
) {
    /** The person's initials, as the design has them, falling back to the organisation for a new profile. */
    val initials: String
        get() = person.ifBlank { organisation }
            .split(" ").filter { it.isNotBlank() }.take(2)
            .joinToString("") { it.first().uppercase() }
            .ifEmpty { "?" }
}

/**
 * The profiles the app can act as, and which one is active. In memory until profiles are a real account concern.
 *
 * @param seed must not be empty; an empty list would otherwise surface far from here, as the products
 * screen throwing on its first read of the active profile.
 */
class UseSmileIDSampleProfiles(seed: List<UseSmileIDSampleProfile> = defaults()) {

    init {
        require(seed.isNotEmpty()) { "UseSmileIDSampleProfiles needs at least one profile" }
    }

    private val items = seed.toMutableStateList()

    var activeId by mutableStateOf(seed.first().id)
        private set

    val all: List<UseSmileIDSampleProfile> get() = items

    val active: UseSmileIDSampleProfile get() = items.firstOrNull { it.id == activeId } ?: items.first()

    fun setActive(id: String) {
        if (items.any { it.id == id }) activeId = id
    }

    fun find(id: String) = items.firstOrNull { it.id == id }

    fun add(organisation: String, person: String): UseSmileIDSampleProfile {
        // First free id, not one derived from the count: duplicate keys crash the list and double a test id.
        val id = generateSequence(items.size + 1) { it + 1 }
            .map { "p-$it" }
            .first { candidate -> items.none { it.id == candidate } }
        val profile = UseSmileIDSampleProfile(
            id = id,
            organisation = organisation,
            person = person,
            environment = UseSmileIDSampleEnvironment.Sandbox,
        )
        items.add(profile)
        return profile
    }

    fun setDefaults(id: String, defaults: UseSmileIDSampleUserDetails) {
        val index = items.indexOfFirst { it.id == id }
        if (index >= 0) items[index] = items[index].copy(defaults = defaults)
    }

    companion object {
        /** The three the design's sheet shows, one in production so the environment chip has a real source. */
        fun defaults() = listOf(
            UseSmileIDSampleProfile(
                id = "p-1",
                organisation = "UpTech Finance",
                person = "Kwame Asante",
                environment = UseSmileIDSampleEnvironment.Sandbox,
                defaults = UseSmileIDSampleUserDetails(firstName = "Kwame", lastName = "Asante"),
            ),
            UseSmileIDSampleProfile(
                id = "p-2",
                organisation = "Kazi Microlending",
                person = "Amina Diallo",
                environment = UseSmileIDSampleEnvironment.Sandbox,
                defaults = UseSmileIDSampleUserDetails(firstName = "Amina", lastName = "Diallo"),
            ),
            UseSmileIDSampleProfile(
                id = "p-3",
                organisation = "PesaLink",
                person = "Tunde Okafor",
                environment = UseSmileIDSampleEnvironment.Production,
                defaults = UseSmileIDSampleUserDetails(firstName = "Tunde", lastName = "Okafor"),
            ),
        )
    }
}
