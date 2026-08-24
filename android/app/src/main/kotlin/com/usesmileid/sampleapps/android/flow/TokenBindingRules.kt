package com.usesmileid.sampleapps.android.flow

import com.usesmileid.core.exception.InvalidFieldValueException
import com.usesmileid.core.exception.UseSmileIDValidationException
import com.usesmileid.presentation.flow.validation.ValidationState
import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
import com.usesmileid.sampleapps.ui.state.bindsIdDetails
import com.usesmileid.sampleapps.ui.state.bindsRequiredUserDetails
import com.usesmileid.sampleapps.ui.state.userDetailsRequirement

/**
 * The session a run actually submits under. Absent for the two scenarios that are *about* refresh:
 * a scanned token has no refresh journey, and the fixtures are what keep those scenarios meaningful.
 */
internal val FlowLaunchSnapshot.liveSession: UseSmileIDSampleTokenSession?
    get() = session?.takeUnless { scenario.startsExpired }

/** The live-session rule, in one place, so nothing disagrees about whether a token is live. */
internal fun UseSmileIDSampleTokenSession?.liveAt(
    scenario: UseSmileIDSampleScenario,
    nowMillis: Long,
): UseSmileIDSampleTokenSession? = this?.takeIf { !it.hasExpired(nowMillis) && !scenario.startsExpired }

internal fun UseSmileIDSampleAppState.liveSessionAt(nowMillis: Long): UseSmileIDSampleTokenSession? =
    session.liveAt(flowResult.scenario, nowMillis)

/** The ticking read, for callers already recomposing on the clock. */
private val UseSmileIDSampleAppState.liveSession: UseSmileIDSampleTokenSession?
    get() = liveSessionAt(nowMillis)

/**
 * Whether the token this run will submit under binds the user details the SDK requires — both names
 * plus one contact field. When it does the SDK asks nothing more of `userDetails`, so the host's own
 * form has nothing left to collect and the journey may start past it. Read through the same
 * live-session rule the gate uses, so a skipped form can never be followed by a redirect back to it.
 */
val UseSmileIDSampleAppState.tokenBindsUserDetails: Boolean
    get() = liveBindings?.bindsRequiredUserDetails == true

/** Drops the issues the token already answers; every other rule the SDK applies still stands. */
internal fun ValidationState.minus(requirement: UseSmileIDSampleUserDetailsRequirement): ValidationState {
    if (this !is ValidationState.Invalid) return this
    val outstanding = issues.filterNot(requirement::covers)
    return if (outstanding.isEmpty()) ValidationState.Valid else ValidationState.Invalid(outstanding)
}

private fun UseSmileIDSampleUserDetailsRequirement.covers(issue: UseSmileIDValidationException): Boolean {
    val field = (issue as? InvalidFieldValueException) ?: return false
    return when (field.fieldName) {
        "userDetails.givenNames" -> !firstName
        "userDetails.lastName" -> !lastName
        // The contact rule is reported against the object rather than a field, so the reason is what
        // identifies it — anything else raised at that level is not ours to drop.
        "userDetails" -> !contact && field.reason.contains("email", ignoreCase = true)
        else -> false
    }
}

/** What the form must still collect, read through the same live-session rule as the gate. */
val UseSmileIDSampleAppState.tokenUserDetailsRequirement: UseSmileIDSampleUserDetailsRequirement
    get() = liveBindings.userDetailsRequirement()

/** [tokenBindsUserDetails] for the ID form, read through the same live-session rule. */
fun UseSmileIDSampleAppState.tokenBindsIdDetails(product: UseSmileIDSampleProduct): Boolean =
    liveBindings?.bindsIdDetails(product) == true

/** The bindings a run may read, or null when no live token backs it. */
val UseSmileIDSampleAppState.liveBindings: UseSmileIDSampleTokenBindings?
    get() = liveSession?.bindings

internal val UseSmileIDSampleScenario.startsExpired: Boolean
    get() = this == UseSmileIDSampleScenario.ExpiredToken || this == UseSmileIDSampleScenario.BadRefresh
