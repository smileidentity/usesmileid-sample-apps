package com.usesmileid.sampleapps.ui.state

/** The stored form of the profiles, one JSON value shared by all four apps so a record reads the same in each. */
object UseSmileIDSampleProfilesCodec {

    const val VERSION = 1

    fun encode(record: UseSmileIDSampleProfilesRecord): String = buildString {
        append("{\"version\":").append(VERSION)
        append(",\"activeId\":").append(record.activeId?.let(::quoted) ?: "null")
        append(",\"profiles\":[")
        record.profiles.forEachIndexed { index, profile ->
            if (index > 0) append(',')
            append('{')
            listOf(
                "id" to profile.id,
                "organisation" to profile.organisation,
                "firstName" to profile.defaults.firstName,
                "lastName" to profile.defaults.lastName,
                "email" to profile.defaults.email,
                "phone" to profile.defaults.phone,
                "callbackUrl" to profile.callbackUrl,
            ).joinTo(this, ",") { (key, value) -> "${quoted(key)}:${quoted(value)}" }
            append('}')
        }
        append("]}")
    }

    /** Anything unreadable, including a version this build does not know, is no profiles: never a crash. */
    fun decode(text: String?): UseSmileIDSampleProfilesRecord {
        val root = text?.let(::parseTokenJson) as? TokenJson.Obj ?: return UseSmileIDSampleProfilesRecord()
        if ((root.members["version"] as? TokenJson.Num)?.literal != VERSION.toString()) return UseSmileIDSampleProfilesRecord()
        val profiles = (root.members["profiles"] as? TokenJson.Arr)?.items.orEmpty()
            .mapNotNull { (it as? TokenJson.Obj)?.profile() }
            .distinctBy { it.id }
        return UseSmileIDSampleProfilesRecord(profiles = profiles, activeId = root.string("activeId"))
    }

    private fun TokenJson.Obj.profile(): UseSmileIDSampleProfile? {
        val id = string("id")?.takeIf { it.isNotBlank() } ?: return null
        return UseSmileIDSampleProfile(
            id = id,
            organisation = string("organisation").orEmpty(),
            defaults = UseSmileIDSampleUserDetails(
                firstName = string("firstName").orEmpty(),
                lastName = string("lastName").orEmpty(),
                email = string("email").orEmpty(),
                phone = string("phone").orEmpty(),
            ),
            callbackUrl = string("callbackUrl").orEmpty(),
        )
    }

    private fun quoted(value: String): String = buildString {
        append('"')
        value.forEach { char ->
            when {
                char == '"' -> append("\\\"")
                char == '\\' -> append("\\\\")
                char < ' ' -> append("\\u%04x".format(char.code))
                else -> append(char)
            }
        }
        append('"')
    }
}
