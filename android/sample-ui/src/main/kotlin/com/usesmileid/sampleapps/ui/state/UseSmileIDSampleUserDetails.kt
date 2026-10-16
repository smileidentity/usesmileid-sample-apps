package com.usesmileid.sampleapps.ui.state

import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import com.usesmileid.sampleapps.ui.R
import com.usesmileid.sampleapps.ui.UseSmileIDSampleStrings
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
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

    /** Whether the form has collected what [requirement] still asks of it; the API judges each value's format. */
    fun satisfies(requirement: UseSmileIDSampleUserDetailsRequirement): Boolean =
        (!requirement.firstName || firstName.isNotBlank()) &&
            (!requirement.lastName || lastName.isNotBlank()) &&
            (!requirement.contact || email.isNotBlank() || phone.isNotBlank())

    /** The email as the server wants it, or null when blank. */
    val submittedEmail: String?
        get() = UseSmileIDSampleContactRules.submitted(UseSmileIDSampleUserField.Email, email).ifEmpty { null }

    /** The phone number as the server wants it, or null when blank. */
    val submittedPhone: String?
        get() = UseSmileIDSampleContactRules.submitted(UseSmileIDSampleUserField.Phone, phone).ifEmpty { null }

    /** These details with every name [requirement] does not show left blank, since a row the form hides submits nothing. */
    fun withoutHiddenNames(requirement: UseSmileIDSampleUserDetailsRequirement): UseSmileIDSampleUserDetails = copy(
        firstName = firstName.takeIf { requirement.shows(UseSmileIDSampleUserField.FirstName) }.orEmpty(),
        lastName = lastName.takeIf { requirement.shows(UseSmileIDSampleUserField.LastName) }.orEmpty(),
    )

    companion object {
        val Saver: Saver<MutableState<UseSmileIDSampleUserDetails>, Any> = listSaver(
            save = { listOf(it.value.firstName, it.value.lastName, it.value.email, it.value.phone) },
            restore = { mutableStateOf(UseSmileIDSampleUserDetails(it[0], it[1], it[2], it[3])) },
        )
    }
}

/**
 * What the form must still collect, and which rows it leaves out: the product's `fields_to_collect`, or the token
 * rule without one. The static `required` flags below cannot express either.
 */
@Immutable
data class UseSmileIDSampleUserDetailsRequirement(
    val firstName: Boolean = true,
    val lastName: Boolean = true,
    val contact: Boolean = true,
    val hidden: Set<UseSmileIDSampleUserField> = emptySet(),
) {
    /** Whether the form draws [field]'s row; a name the partner may leave out is not drawn at all. */
    fun shows(field: UseSmileIDSampleUserField): Boolean = field !in hidden

    /** Nothing left to ask, so the form has no reason to appear. */
    val isSatisfied: Boolean get() = !firstName && !lastName && !contact

    /** No relevant binding at all, which is the one case the SDK's own validator can still decide. */
    val bindsNothing: Boolean get() = firstName && lastName && contact

    /** Whether [field] is one the token already supplied, which is why it renders as provided. */
    fun supplies(field: UseSmileIDSampleUserField): Boolean = when (field) {
        UseSmileIDSampleUserField.FirstName -> !firstName && shows(field)
        UseSmileIDSampleUserField.LastName -> !lastName && shows(field)
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

/** The requirement a token leaves behind: each name and one contact, unless the token binds it. */
fun UseSmileIDSampleTokenBindings?.userDetailsRequirement() = UseSmileIDSampleUserDetailsRequirement(
    firstName = this?.givenNames != true,
    lastName = this?.lastName != true,
    contact = !(this?.email == true || this?.phoneNumber == true),
)

/** The token rule, less any name [product]'s `fields_to_collect` does not require (spec/user-details-fields.json). */
fun UseSmileIDSampleTokenBindings?.userDetailsRequirement(
    product: UseSmileIDSampleProduct?,
    fieldsToCollect: Map<String, List<UseSmileIDSampleApiField>>?,
): UseSmileIDSampleUserDetailsRequirement {
    val token = userDetailsRequirement()
    val fields = product?.fieldsToCollectKey?.let { fieldsToCollect?.get(it) } ?: return token
    fun leftOut(name: String, asked: Boolean) = asked && fields.none { it.name == name && it.required == true }
    val hidden = buildSet {
        if (leftOut("given_names", token.firstName)) add(UseSmileIDSampleUserField.FirstName)
        if (leftOut("last_name", token.lastName)) add(UseSmileIDSampleUserField.LastName)
    }
    return token.copy(
        firstName = token.firstName && UseSmileIDSampleUserField.FirstName !in hidden,
        lastName = token.lastName && UseSmileIDSampleUserField.LastName !in hidden,
        hidden = hidden,
    )
}

/** The product's key in `fields_to_collect`; null for the SmartSelfie products, which have none. */
val UseSmileIDSampleProduct.fieldsToCollectKey: String?
    get() = when (this) {
        UseSmileIDSampleProduct.SmartSelfieEnrollment, UseSmileIDSampleProduct.SmartSelfieAuth -> null
        UseSmileIDSampleProduct.BiometricKyc -> "biometric_kyc"
        UseSmileIDSampleProduct.EnhancedKyc -> "enhanced_kyc"
        UseSmileIDSampleProduct.DocumentVerification -> "doc_verification"
        UseSmileIDSampleProduct.EnhancedDocumentVerification -> "enhanced_document_verification"
        UseSmileIDSampleProduct.ResidencyDocumentVerification -> "residency_document_verification"
    }

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

/** How `spec/contact-rules.json` submits an email or a phone number; no form checks either. */
object UseSmileIDSampleContactRules {
    private val phoneSeparators = Regex("[\\s().-]")

    /** [value] as it is submitted: trimmed, and a phone number without its separators. */
    fun submitted(field: UseSmileIDSampleUserField, value: String): String = when (field) {
        UseSmileIDSampleUserField.Phone -> value.trim().replace(phoneSeparators, "")
        else -> value.trim()
    }
}
