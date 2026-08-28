package com.usesmileid.sampleapps.android.launch

import android.content.res.Configuration
import android.os.LocaleList
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalResources

/**
 * Honours `appLocale`: every string the app renders, the SDK's own localized text included, resolves
 * in the requested BCP 47 tag without touching device settings that some OEMs will not script.
 */
@Composable
fun UseSmileIDSampleAppLocale(tag: String?, content: @Composable () -> Unit) {
    val requested = remember(tag) { tag?.let(::useSmileIDSampleLocales) }
    if (requested == null) {
        LaunchedEffect(tag) {
            if (tag != null) Log.w(TAG, "appLocale=$tag did nothing: not a usable BCP 47 tag")
        }
        content()
        return
    }

    val configuration = LocalConfiguration.current
    val localized = remember(configuration, requested) {
        Configuration(configuration).apply { setLocales(requested) }
    }
    val context = LocalContext.current
    // Resources rather than the context: the SDK reads every string through `stringResource`, and
    // substituting LocalContext would take the Activity its screens unwrap to out of the chain.
    val localizedResources = remember(context, localized) {
        context.createConfigurationContext(localized).resources
    }

    LaunchedEffect(requested, configuration.locales) {
        if (configuration.locales.toLanguageTags() == requested.toLanguageTags()) {
            Log.w(TAG, "appLocale=$tag is already the device locale — the run proves nothing about localization")
        } else {
            Log.i(TAG, "appLocale=$tag applied over ${configuration.locales.toLanguageTags()}")
        }
    }

    CompositionLocalProvider(
        LocalConfiguration provides localized,
        LocalResources provides localizedResources,
        content = content,
    )
}

/** Null when the tag names no language: an undefined locale would silently render the default. */
internal fun useSmileIDSampleLocales(tag: String): LocaleList? {
    val locales = LocaleList.forLanguageTags(tag)
    if (locales.isEmpty) return null
    val usable = (0 until locales.size()).none { locales[it].language.isNullOrBlank() }
    return if (usable) locales else null
}

/** Matches the file, and stays inside the 23-character tag limit that API 24-25 still enforces. */
private const val TAG = "UseSmileIDAppLocale"
