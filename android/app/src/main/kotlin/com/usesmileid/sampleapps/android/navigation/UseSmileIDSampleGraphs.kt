package com.usesmileid.sampleapps.android.navigation

import com.ramcosta.composedestinations.annotation.NavGraph
import com.ramcosta.composedestinations.annotation.RootGraph

/**
 * One nested graph per tab, so each tab owns a back stack that survives switching away and back.
 * Everything else sits directly in [RootGraph], above the shell, so it can cover the nav bar.
 */
@NavGraph<RootGraph>(start = true)
annotation class ProductsGraph

@NavGraph<RootGraph>
annotation class VerificationsGraph

@NavGraph<RootGraph>
annotation class SettingsGraph
