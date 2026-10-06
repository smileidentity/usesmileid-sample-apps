package com.usesmileid.sampleapps.android.launch

import android.content.res.Configuration
import android.os.LocaleList
import android.text.TextUtils
import android.util.Log
import android.view.View
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalResources
import androidx.compose.ui.unit.LayoutDirection

/** Renders everything below, the SDK's screens included, in [tag]; null keeps the device's. */
@Composable
fun UseSmileIDSampleAppLocale(tag: String?, content: @Composable () -> Unit) {
    val requested = remember(tag) { tag?.let(::useSmileIDSampleLocales) }
    val configuration = LocalConfiguration.current
    val context = LocalContext.current
    val deviceResources = LocalResources.current
    val deviceDirection = LocalLayoutDirection.current
    val localized = remember(configuration, requested) {
        requested?.let { Configuration(configuration).apply { setLocales(it) } } ?: configuration
    }
    // Resources rather than the context: the SDK reads every string through `stringResource`, and
    // substituting LocalContext would take the Activity its screens unwrap to out of the chain.
    val localizedResources = remember(context, localized, deviceResources) {
        if (requested == null) deviceResources else context.createConfigurationContext(localized).resources
    }

    LaunchedEffect(tag, configuration.locales) {
        when {
            requested != null -> Log.i(TAG, "locale $tag applied over ${configuration.locales.toLanguageTags()}")
            tag != null -> Log.w(TAG, "locale $tag did nothing: not a usable BCP 47 tag")
        }
    }

    // Compose reads direction from the view, not LocalConfiguration.
    val direction = when {
        requested == null -> deviceDirection
        TextUtils.getLayoutDirectionFromLocale(requested[0]) == View.LAYOUT_DIRECTION_RTL -> LayoutDirection.Rtl
        else -> LayoutDirection.Ltr
    }
    // Always this provider: a bare `content()` changes the composition's shape and drops remembered state.
    CompositionLocalProvider(
        LocalConfiguration provides localized,
        LocalResources provides localizedResources,
        LocalLayoutDirection provides direction,
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
