package com.usesmileid.sampleapps.ui.state

import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
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

    /** Whether the form has collected what [requirement] still asks of it, in a form the server accepts. */
    fun satisfies(requirement: UseSmileIDSampleUserDetailsRequirement): Boolean =
        (!requirement.firstName || firstName.isNotBlank()) &&
            (!requirement.lastName || lastName.isNotBlank()) &&
            (!requirement.contact || email.isNotBlank() || phone.isNotBlank()) &&
            contactProblem == null

    /** Why the email or phone would fail the job, email first; null when both would pass. */
    @get:StringRes
    val contactProblem: Int?
        get() = UseSmileIDSampleContactRules.problem(UseSmileIDSampleUserField.Email, email)
            ?: UseSmileIDSampleContactRules.problem(UseSmileIDSampleUserField.Phone, phone)

    /** The email as the server wants it, or null when blank. */
    val submittedEmail: String?
        get() = UseSmileIDSampleContactRules.submitted(UseSmileIDSampleUserField.Email, email).ifEmpty { null }

    /** The phone number as the server wants it, or null when blank. */
    val submittedPhone: String?
        get() = UseSmileIDSampleContactRules.submitted(UseSmileIDSampleUserField.Phone, phone).ifEmpty { null }

    companion object {
        val Saver: Saver<MutableState<UseSmileIDSampleUserDetails>, Any> = listSaver(
            save = { listOf(it.value.firstName, it.value.lastName, it.value.email, it.value.phone) },
            restore = { mutableStateOf(UseSmileIDSampleUserDetails(it[0], it[1], it[2], it[3])) },
        )
    }
}

/**
 * What the form must still collect: the SDK's rule minus what the token binds. The static `required` flags
 * below cannot express either half of that.
 */
@Immutable
data class UseSmileIDSampleUserDetailsRequirement(
    val firstName: Boolean = true,
    val lastName: Boolean = true,
    val contact: Boolean = true,
) {
    /** Nothing left to ask, so the form has no reason to appear. */
    val isSatisfied: Boolean get() = !firstName && !lastName && !contact

    /** No relevant binding at all, which is the one case the SDK's own validator can still decide. */
    val bindsNothing: Boolean get() = firstName && lastName && contact

    /** Whether [field] is one the token already supplied, which is why it renders as provided. */
    fun supplies(field: UseSmileIDSampleUserField): Boolean = when (field) {
        UseSmileIDSampleUserField.FirstName -> !firstName
        UseSmileIDSampleUserField.LastName -> !lastName
        // Neither contact row is individually supplied: the rule is "one of", so a bound email leaves
        // phone askable and vice versa. Only the requirement itself lifts.
        UseSmileIDSampleUserField.Email, UseSmileIDSampleUserField.Phone -> false
    }

    /** A contact row stops saying "optional" the moment one of the two is actually required. */
    @StringRes
    fun labelFor(field: UseSmileIDSampleUserField): Int = when {
        !contact -> field.label
        field == UseSmileIDSampleUserField.Email -> R.string.sample_user_field_email
        field == UseSmileIDSampleUserField.Phone -> R.string.sample_user_field_phone
        else -> field.label
    }

    /** The sentence under the form, which has to name what is actually outstanding. */
    @Composable
    fun prompt(): String {
        val outstanding = buildList {
            if (firstName) add(UseSmileIDSampleStrings.userRequirementFirstName)
            if (lastName) add(UseSmileIDSampleStrings.userRequirementLastName)
            if (contact) add(UseSmileIDSampleStrings.userRequirementContact)
        }
        return when {
            outstanding.isEmpty() -> UseSmileIDSampleStrings.userDetailsEditHint
            outstanding.size == 1 -> UseSmileIDSampleStrings.userRequirementOne(outstanding.single())
            else -> UseSmileIDSampleStrings.userRequirementMany(outstanding.joinToString(UseSmileIDSampleStrings.userRequirementSeparator))
        }.replaceFirstChar(Char::titlecase)
    }
}

/**
 * The requirement a token leaves behind. Mirrors the SDK's union rule field for field, and the unit
 * tests pin it to `FlowValidator.validateUserDetails`, which is the authority.
 */
fun UseSmileIDSampleTokenBindings?.userDetailsRequirement() = UseSmileIDSampleUserDetailsRequirement(
    firstName = this?.givenNames != true,
    lastName = this?.lastName != true,
    contact = !(this?.email == true || this?.phoneNumber == true),
)

/** Which user-details row changed, so the form reports one callback rather than four. */
enum class UseSmileIDSampleUserField(
    val id: String,
    @StringRes val label: Int,
    @StringRes val placeholder: Int,
    val required: Boolean,
) {
    FirstName("firstName", R.string.sample_user_field_first_name, R.string.sample_user_field_first_name_placeholder, required = true),
    LastName("lastName", R.string.sample_user_field_last_name, R.string.sample_user_field_last_name_placeholder, required = true),
    Email("email", R.string.sample_user_field_email_optional, R.string.sample_user_field_email_placeholder, required = false),
    Phone("phone", R.string.sample_user_field_phone_optional, R.string.sample_user_field_phone_placeholder, required = false),
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

/** The email and phone checks from `spec/contact-rules.json`, which mirror the v3 API's own request schema. */
object UseSmileIDSampleContactRules {
    @StringRes val EMAIL_ERROR = R.string.sample_user_field_email_error

    @StringRes val PHONE_ERROR = R.string.sample_user_field_phone_error

    private val email = Regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$")
    private val phoneSeparators = Regex("[\\s().-]")
    private val phone = Regex("^\\+[1-9][0-9]{6,14}$")

    /** [value] as it is submitted: trimmed, and a phone number without its separators. */
    fun submitted(field: UseSmileIDSampleUserField, value: String): String = when (field) {
        UseSmileIDSampleUserField.Phone -> value.trim().replace(phoneSeparators, "")
        else -> value.trim()
    }

    /** Why [value] would fail the job as [field], or null when it would pass; blank always passes. */
    @StringRes
    fun problem(field: UseSmileIDSampleUserField, value: String): Int? {
        val submitted = submitted(field, value)
        if (submitted.isEmpty()) return null
        return when (field) {
            UseSmileIDSampleUserField.Email -> EMAIL_ERROR.takeUnless { email.matches(submitted) }
            UseSmileIDSampleUserField.Phone -> PHONE_ERROR.takeUnless { phone.matches(submitted) }
            else -> null
        }
    }
}
