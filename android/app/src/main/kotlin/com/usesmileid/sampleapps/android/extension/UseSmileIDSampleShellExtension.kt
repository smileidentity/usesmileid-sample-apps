package com.usesmileid.sampleapps.android.extension

import android.content.Intent
import androidx.compose.runtime.Composable
import com.usesmileid.presentation.flow.dsl.UseSmileIDFlowBuilder
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import java.util.ServiceLoader

/** Developer tooling an SDK repo's source build adds to this app; a registry build has none. */
interface UseSmileIDSampleShellExtension {
    /** Extra rows for the Settings DEBUG section, which debug builds show. */
    @Composable
    fun DebugRows(host: UseSmileIDSampleShellHost) {}

    /** Runs after the shell has configured a flow, so it may replace any of that configuration. */
    fun customiseFlow(builder: UseSmileIDFlowBuilder, product: UseSmileIDSampleProduct) {}

    /** Runs once at launch, with the intent the app was started by. */
    fun onLaunch(intent: Intent) {}
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
