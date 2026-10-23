package com.usesmileid.sampleapps.android.extension

import android.content.Intent
import androidx.compose.runtime.Composable
import com.usesmileid.data.dsl.UseSmileIDNetworkBuilder
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import java.util.ServiceLoader
import kotlin.coroutines.cancellation.CancellationException

/** Developer tooling an SDK repo's source build adds to this app; a registry build has none. */
interface UseSmileIDSampleShellExtension {
    /** Rows for the Settings DEBUG section above the shell's own, such as an identity the rows below refer to. */
    @Composable
    fun LeadingDebugRows(host: UseSmileIDSampleShellHost) {}

    /** Extra rows for the Settings DEBUG section, which debug builds show. */
    @Composable
    fun DebugRows(host: UseSmileIDSampleShellHost) {}

    /** Runs after the shell has configured a flow, so it may replace any of that configuration. */
    fun customiseFlow(builder: UseSmileIDFlowBuilder, product: UseSmileIDSampleProduct) {}

    /** Runs last inside the shell's network block; an `interceptors {}` block here replaces the shell's debug interceptors. */
    fun customiseNetwork(network: UseSmileIDNetworkBuilder, product: UseSmileIDSampleProduct) {}

    /** Runs once at launch, with the intent the app was started by. */
    fun onLaunch(intent: Intent) {}

    /** A session the shell links once at launch, before autostart, as if its token had been scanned. */
    fun launchSession(): UseSmileIDSampleTokenSession? = null
}

/** Links the [extension]'s launch session, if it offers one, and returns it; a failed link only skips it. */
suspend fun linkLaunchSession(
    extension: UseSmileIDSampleShellExtension?,
    link: suspend (UseSmileIDSampleTokenSession) -> Unit,
): UseSmileIDSampleTokenSession? = try {
    extension?.launchSession()?.also { link(it) }
} catch (cancelled: CancellationException) {
    throw cancelled
} catch (_: Exception) {
    null
}

/** What the shell lets an extension do. */
interface UseSmileIDSampleShellHost {
    fun linkTokenSession(session: UseSmileIDSampleTokenSession)

    fun openScenarioDrawer()
}

/** The extension on the classpath, found by ServiceLoader so the shell never names SDK-repo code. */
val useSmileIDSampleShellExtension: UseSmileIDSampleShellExtension? by lazy {
    ServiceLoader.load(UseSmileIDSampleShellExtension::class.java).firstOrNull()
}
