package com.usesmileid.sampleapps.android.navigation

import com.ramcosta.composedestinations.annotation.NavGraph
import com.ramcosta.composedestinations.annotation.RootGraph

/**
 * One nested graph per tab, so each tab owns a back stack that survives switching away and back,
 * plus one for the pre-flow wizard. Everything else sits directly in [RootGraph].
 */
@NavGraph<RootGraph>(start = true)
annotation class ProductsGraph

@NavGraph<RootGraph>
annotation class VerificationsGraph

@NavGraph<RootGraph>
annotation class SettingsGraph

/** The wizard plus the flow itself: one `popUpTo` target when a result replaces them all (R4). */
@NavGraph<RootGraph>
annotation class FlowGraph
