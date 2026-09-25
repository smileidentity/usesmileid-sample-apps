package com.usesmileid.sampleapps.ui.state

import androidx.compose.runtime.Immutable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList

/** One persona a job runs as: the organisation the SDK's consent screen names, and the details its jobs carry. */
@Immutable
data class UseSmileIDSampleProfile(
    val id: String,
    /** May be blank, when consent names the app itself rather than the person being verified. */
    val organisation: String,
    val defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
    /** Empty means the partner's portal default. */
    val callbackUrl: String = "",
) {
    /** The person the details name, so it can never disagree with them. */
    val person: String get() = "${defaults.firstName} ${defaults.lastName}".trim()

    /** What a row calls it: the organisation, or the person when it names none. */
    val title: String get() = organisation.ifBlank { person }.ifBlank { UNNAMED_PROFILE }

    /** The person's initials, as the design has them, falling back to the organisation. */
    val initials: String
        get() = person.ifBlank { organisation }
            .split(" ").filter { it.isNotBlank() }.take(2)
            .joinToString("") { it.first().uppercase() }
            .ifEmpty { "?" }

    /** What a row says under the organisation: the person, or a placeholder until details are saved. */
    val caption: String
        get() = person.ifBlank { NO_USER_DETAILS_CAPTION }
}

/** What is stored: the profiles and which is active. Null [activeId] exactly when there are none. */
@Immutable
data class UseSmileIDSampleProfilesRecord(
    val profiles: List<UseSmileIDSampleProfile> = emptyList(),
    val activeId: String? = profiles.firstOrNull()?.id,
)

/** The profiles the app can act as, and which one is active; a plain first launch has none. [onChange] stores each change, null for a launch that writes nothing. */
class UseSmileIDSampleProfiles(
    seed: UseSmileIDSampleProfilesRecord = UseSmileIDSampleProfilesRecord(),
    loaded: Boolean = true,
    private val onChange: ((UseSmileIDSampleProfilesRecord) -> Unit)? = null,
) {

    private val items = seed.profiles.toMutableStateList()

    var activeId: String? by mutableStateOf(seed.validActiveId())
        private set

    /** False until the stored profiles have been read, so a form does not fill from a list still loading. */
    var loaded by mutableStateOf(loaded)
        private set

    /** The last profile [add] created without activating, until the list that offers "Make active" consumes it. */
    var lastCreatedId: String? by mutableStateOf(null)
        private set

    val all: List<UseSmileIDSampleProfile> get() = items

    val active: UseSmileIDSampleProfile? get() = items.firstOrNull { it.id == activeId }

    /** Position in the list, which is what picks a profile's avatar hue. */
    val activeIndex: Int get() = items.indexOfFirst { it.id == activeId }.coerceAtLeast(0)

    /** What the consent screen names as the partner: the app's own name when no profile names one. */
    val partnerName: String get() = active?.organisation?.takeIf { it.isNotBlank() } ?: NO_PROFILE_PARTNER_NAME

    /** The id a job runs under without a token: the first profile's own id when there is none yet. */
    val partnerId: String get() = active?.id ?: FIRST_PROFILE_ID

    val record: UseSmileIDSampleProfilesRecord get() = UseSmileIDSampleProfilesRecord(items.toList(), activeId)

    /** Adopts what the store read, once; a sign-out tapped before it arrived still wins. */
    fun restore(stored: UseSmileIDSampleProfilesRecord) {
        if (loaded) return
        items.clear()
        activeId = null
        loaded = true
        if (clearedBeforeLoad) {
            changed()
            return
        }
        items.addAll(stored.profiles)
        activeId = stored.validActiveId()
    }

    private var clearedBeforeLoad = false

    fun setActive(id: String) {
        if (items.none { it.id == id } || id == activeId) return
        activeId = id
        changed()
    }

    fun clearLastCreated() {
        lastCreatedId = null
    }

    fun find(id: String) = items.firstOrNull { it.id == id }

    /** The first profile ever made becomes active, so a list with profiles always has one active. */
    fun add(
        organisation: String,
        defaults: UseSmileIDSampleUserDetails = UseSmileIDSampleUserDetails(),
        activate: Boolean = false,
    ): UseSmileIDSampleProfile {
        // First free id, not one derived from the count: duplicate keys crash the list and double a test id.
        val id = generateSequence(items.size + 1) { it + 1 }
            .map { "p-$it" }
            .first { candidate -> items.none { it.id == candidate } }
        val profile = UseSmileIDSampleProfile(id = id, organisation = organisation.trim(), defaults = defaults)
        items.add(profile)
        if (activate || activeId == null) activeId = id else lastCreatedId = id
        changed()
        return profile
    }

    /** A null argument leaves that part alone. */
    fun update(
        id: String,
        organisation: String? = null,
        defaults: UseSmileIDSampleUserDetails? = null,
        callbackUrl: String? = null,
    ) {
        val index = items.indexOfFirst { it.id == id }
        if (index < 0) return
        val current = items[index]
        val updated = current.copy(
            organisation = organisation?.trim() ?: current.organisation,
            defaults = defaults ?: current.defaults,
            callbackUrl = callbackUrl?.trim() ?: current.callbackUrl,
        )
        if (updated == current) return
        items[index] = updated
        changed()
    }

    /** Deleting the active profile hands over to the first one left, so a list with profiles always has one active. */
    fun delete(id: String) {
        if (!items.removeAll { it.id == id }) return
        if (activeId == id) activeId = items.firstOrNull()?.id
        if (lastCreatedId == id) lastCreatedId = null
        changed()
    }

    /** Sign out: every profile goes, which is how a phone is handed to the next person. */
    fun clear() {
        if (!loaded) clearedBeforeLoad = true
        if (items.isEmpty()) return
        items.clear()
        activeId = null
        lastCreatedId = null
        changed()
    }

    /** Nothing is stored before the store has answered, or a partial list would replace what it holds. */
    private fun changed() {
        if (loaded) onChange?.invoke(record)
    }

    companion object {
        /** The fixtures only when `seedProfiles` asks, and never stored: an automation run must not leave people behind. */
        fun forLaunch(
            args: UseSmileIDSampleLaunchArgs,
            onChange: (UseSmileIDSampleProfilesRecord) -> Unit,
        ) = if (args.seedProfiles) {
            UseSmileIDSampleProfiles(UseSmileIDSampleProfilesRecord(fixtures()))
        } else {
            UseSmileIDSampleProfiles(loaded = false, onChange = onChange)
        }

        /** The three the design's sheet shows. Reached only by the `seedProfiles` launch argument — see `spec/launch-args.json`. */
        fun fixtures() = listOf(
            UseSmileIDSampleProfile(
                id = "p-1",
                organisation = "UpTech Finance",
                defaults = UseSmileIDSampleUserDetails(firstName = "Kwame", lastName = "Asante"),
            ),
            UseSmileIDSampleProfile(
                id = "p-2",
                organisation = "Kazi Microlending",
                defaults = UseSmileIDSampleUserDetails(firstName = "Amina", lastName = "Diallo"),
            ),
            UseSmileIDSampleProfile(
                id = "p-3",
                organisation = "PesaLink",
                defaults = UseSmileIDSampleUserDetails(firstName = "Tunde", lastName = "Okafor"),
            ),
        )

        /** The partner the consent screen names when no profile does. */
        const val NO_PROFILE_PARTNER_NAME = "Smile ID"

        /** What a plain launch has always sent as the partner id, so no profile changes nothing on the wire. */
        const val FIRST_PROFILE_ID = "p-1"

        /** What the header, settings card and form say while there is no profile. */
        const val NO_PROFILE_LABEL = "No profile yet"
    }
}

private fun UseSmileIDSampleProfilesRecord.validActiveId(): String? =
    activeId?.takeIf { id -> profiles.any { it.id == id } } ?: profiles.firstOrNull()?.id

private const val NO_USER_DETAILS_CAPTION = "No user details yet"

/** A profile naming neither an organisation nor a person, which only a token binding both names allows. */
private const val UNNAMED_PROFILE = "Unnamed profile"
