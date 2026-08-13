package com.usesmileid.sampleapps.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.usesmileid.sampleapps.ui.theme.SampleTheme

/**
 * The app's single entry point.
 *
 * Single-activity on purpose: the SDK flow is a destination inside this app's own graph, so every
 * route — including the flow — is reachable by one deep link into one activity.
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            SampleTheme {
                SampleAppShell()
            }
        }
    }
}
