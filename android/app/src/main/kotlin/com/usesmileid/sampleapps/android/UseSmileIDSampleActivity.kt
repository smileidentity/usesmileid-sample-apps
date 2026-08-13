package com.usesmileid.sampleapps.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.usesmileid.sampleapps.ui.theme.UseSmileIDSampleTheme

/** Single-activity host: every route, including the SDK flow, is a destination in one graph. */
class UseSmileIDSampleActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            UseSmileIDSampleTheme {
                UseSmileIDSampleShell()
            }
        }
    }
}
