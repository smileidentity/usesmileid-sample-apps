package com.usesmileid.sampleapps.android.flow

import com.ramcosta.composedestinations.generated.destinations.SdkFlowScreenDestinationNavArgs
import com.usesmileid.sampleapps.android.UseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowRoute
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleScenario
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleThemeScenario
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdDetails
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleUserDetails

/** Read once at flow entry; never re-read while the flow runs (R2). */
data class FlowLaunchSnapshot(
    val product: UseSmileIDSampleProduct,
    val route: UseSmileIDSampleFlowRoute,
    val userDetails: UseSmileIDSampleUserDetails,
    val idDetails: UseSmileIDSampleIdDetails,
    val scenario: UseSmileIDSampleScenario,
    val theme: UseSmileIDSampleThemeScenario,
    val sandbox: Boolean,
    val userId: String,
    val partnerId: String,
    val partnerName: String,
    /** Live at entry only: a session that has run out is the gate's business, never the builder's. */
    val session: UseSmileIDSampleTokenSession? = null,
    /**
     * A session existed and has run out — the one thing that routes back to the scanner (TOK-A5).
     * Usually true with no [session] at all, because the token is deleted at its deadline and only a
     * marker survives; the two are independent for the window before that delete lands.
     */
    val sessionExpired: Boolean = false,
)

fun buildSnapshot(
    args: SdkFlowScreenDestinationNavArgs,
    app: UseSmileIDSampleAppState,
    userId: String,
): FlowLaunchSnapshot? {
    val product = UseSmileIDSampleProduct.entries.firstOrNull { it.id == args.productId } ?: return null
    // The clock is read here rather than through the app state's ticking value: the snapshot is taken
    // once at entry (R2), and subscribing the flow host to a once-a-second tick would recompose it —
    // which the SDK answers by re-running `build()` and tearing the run down.
    val entryMillis = System.currentTimeMillis()
    val session = app.session
    return FlowLaunchSnapshot(
        product = product,
        route = args.route,
        userDetails = app.forms.userDetails,
        idDetails = app.forms.idDetails,
        scenario = app.flowResult.scenario,
        theme = app.flowResult.theme,
        sandbox = app.useSandbox,
        userId = userId,
        partnerId = app.profiles.active.id,
        partnerName = app.profiles.active.organisation,
        session = session?.takeUnless { it.hasExpired(entryMillis) },
        // The marker outlives the token it came from, so it is the durable half of this answer.
        sessionExpired = app.endedSession != null || (session != null && session.hasExpired(entryMillis)),
    )
}
