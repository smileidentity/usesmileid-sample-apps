package com.usesmileid.sampleapps.android.flow

import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiField
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetailsRequirement
import com.usesmileid.sampleapps.ui.state.bindsIdDetails
import com.usesmileid.sampleapps.ui.state.bindsRequiredUserDetails
import com.usesmileid.sampleapps.ui.state.entryFor
import com.usesmileid.sampleapps.ui.state.userDetailsRequirement

/**
 * The session a run actually submits under. Absent for the two scenarios that are *about* refresh:
 * a scanned token has no refresh journey, and the fixtures are what keep those scenarios meaningful.
 */
internal val FlowLaunchSnapshot.liveSession: UseSmileIDSampleTokenSession?
    get() = session?.takeUnless { scenario.startsExpired }

/** Dropped under a live session, as the partner id already is: the token's partner owns the job. */
internal fun resolveCallbackUrl(snapshot: FlowLaunchSnapshot): String =
    if (snapshot.liveSession != null) "" else snapshot.callbackUrl

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

/** What the form asks for [product], read through the gate's live-session rule and only that session's configuration. */
fun UseSmileIDSampleAppState.userDetailsRequirement(product: UseSmileIDSampleProduct?): UseSmileIDSampleUserDetailsRequirement =
    liveSession.let { live ->
        live?.bindings.userDetailsRequirement(product, catalogue.fieldsToCollectFor(live?.id), catalogue.idTypeFieldsFor(live?.id))
    }

/** The picked ID type's fields for [product], read through the same live-session rule, or null without an entry. */
fun UseSmileIDSampleAppState.idTypeEntry(product: UseSmileIDSampleProduct?): List<UseSmileIDSampleApiField>? =
    catalogue.idTypeFieldsFor(liveSession?.id).entryFor(product, forms.idDetails.country?.code, forms.idDetails.idType?.type)

/** [tokenBindsUserDetails] for the ID form, read through the same live-session rule. */
fun UseSmileIDSampleAppState.tokenBindsIdDetails(product: UseSmileIDSampleProduct): Boolean =
    liveBindings?.bindsIdDetails(product) == true

/** Whether the token has taken the consent decision away. Clock-free: Settings must not recompose on the tick. */
internal val UseSmileIDSampleAppState.tokenBindsConsent: Boolean
    get() = session?.takeUnless { flowResult.scenario.startsExpired }?.bindings?.consent != null

/** The bindings a run may read, or null when no live token backs it. */
val UseSmileIDSampleAppState.liveBindings: UseSmileIDSampleTokenBindings?
    get() = liveSession?.bindings

internal val UseSmileIDSampleScenario.startsExpired: Boolean
    get() = this == UseSmileIDSampleScenario.ExpiredToken || this == UseSmileIDSampleScenario.BadRefresh
