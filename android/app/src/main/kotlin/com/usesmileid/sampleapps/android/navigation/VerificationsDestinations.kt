package com.usesmileid.sampleapps.android.navigation

import android.content.ClipData
import android.os.Build
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ClipEntry
import androidx.compose.ui.platform.LocalClipboard
import com.ramcosta.composedestinations.annotation.Destination
import com.ramcosta.composedestinations.annotation.parameters.DeepLink
import com.ramcosta.composedestinations.generated.destinations.VerificationDetailsScreenDestination
import com.ramcosta.composedestinations.navigation.DestinationsNavigator
import com.smileid.designsystem.SmileDimens
import com.usesmileid.sampleapps.android.BuildConfig
import com.usesmileid.sampleapps.android.LocalUseSmileIDSampleAppState
import com.usesmileid.sampleapps.ui.components.UseSmileIDSampleTransientNoticeHost
import com.usesmileid.sampleapps.ui.components.rememberTransientNotice
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleStatusRefresh
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.model.startOfDayMillis
import com.usesmileid.sampleapps.ui.screens.UseSmileIDSampleVerificationsState
import com.usesmileid.sampleapps.ui.screens.rememberVerificationsScreenState
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import com.usesmileid.sampleapps.ui.screens.VerificationDetailsScreen as VerificationDetailsContent
import com.usesmileid.sampleapps.ui.screens.VerificationsScreen as VerificationsContent

/** The verifications tab's routes. Function names are load-bearing: KSP names each generated `…Destination` after the function. */

@Destination<VerificationsGraph>(start = true, deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.VERIFICATIONS)])
@Composable
fun VerificationsScreen(navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val screen = rememberVerificationsScreenState()
    val notice = rememberTransientNotice()

    // None of the list derivations read the clock; recompute on data change, not on the session tick.
    val jobs = app.jobs
    // Counted off the same list the rows render from, so a count can never disagree with what is on screen.
    val counts = remember(jobs) { UseSmileIDSampleJobFilter.entries.associateWith { f -> jobs.orEmpty().count(f::matches) } }
    // The grouping only cares which day it is, so per-second ticks must not invalidate it.
    val todayStart by remember { derivedStateOf { startOfDayMillis(app.nowMillis) } }

    val removeJobs: (Set<String>) -> Unit = { ids ->
        app.storeScope.launch { app.jobStore.remove(ids) }
        screen.changeSelectMode(false)
        // Against the list minus the ids going away: the delete is suspend and has not landed yet.
        if (app.jobs.orEmpty().none { it.id !in ids && screen.filter.matches(it) }) {
            screen.filter = UseSmileIDSampleJobFilter.All
        }
    }

    // Published to the shell rather than drawn here: the design replaces the nav bar with it.
    val chrome = LocalUseSmileIDSampleChrome.current
    LaunchedEffect(screen.selectMode, screen.selected) {
        chrome.selection = if (screen.selectMode) {
            UseSmileIDSampleSelectionChrome(count = screen.selected.size, onRemove = { removeJobs(screen.selected) })
        } else {
            null
        }
    }
    DisposableEffect(Unit) { onDispose { chrome.selection = null } }

    Box(modifier = Modifier.fillMaxSize()) {
        VerificationsContent(
            // The selection bar insets via the Scaffold slot; only the floating nav bar needs clearing here.
            contentPadding = PaddingValues(bottom = chrome.navBarHeight + SmileDimens.spacingMd),
            state = UseSmileIDSampleVerificationsState(
                jobs = jobs,
                counts = counts,
                filter = screen.filter,
                selectMode = screen.selectMode,
                selected = screen.selected,
                todayStartMillis = todayStart,
            ),
            onFilterChange = { screen.filter = it },
            onSelectModeChange = screen::changeSelectMode,
            onSelectionChange = screen::setSelection,
            onJobClick = { navigator.navigate(VerificationDetailsScreenDestination(jobId = it.id)) },
            onRemove = removeJobs,
        )
        // Collected, not polled: the store emits each removal batch exactly once, so a removal made
        // on the details screen is confirmed here too.
        LaunchedEffect(Unit) {
            app.jobStore.removals.collect { count ->
                notice.show(
                    message = if (count == 1) "1 verification hidden from App list" else "$count verifications hidden from App list",
                    actionLabel = "Undo",
                    onAction = { app.storeScope.launch { app.jobStore.undoRemove() } },
                )
            }
        }
        UseSmileIDSampleTransientNoticeHost(
            state = notice,
            // Clears the floating bar itself, which draws over this container rather than insetting it.
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = chrome.navBarHeight)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingXxs),
        )
    }
}

/** Also the post-submission landing route: on a result the flow and both forms are replaced. */
@Destination<VerificationsGraph>(deepLinks = [DeepLink(uriPattern = UseSmileIDSampleDeepLinks.VERIFICATION_DETAILS)])
@Composable
fun VerificationDetailsScreen(jobId: String, navigator: DestinationsNavigator) {
    val app = LocalUseSmileIDSampleAppState.current
    val clipboard = LocalClipboard.current
    val scope = rememberCoroutineScope()
    var refreshing by remember { mutableStateOf(false) }
    val notice = rememberTransientNotice()

    val job = app.jobs?.firstOrNull { it.id == jobId }

    Box(modifier = Modifier.fillMaxSize()) {
        VerificationDetailsContent(
            jobId = jobId,
            job = job,
            result = app.flowResult.snapshot,
            onBack = { navigator.navigateUp() },
            onDelete = { app.storeScope.launch { app.jobStore.remove(setOf(jobId)) }; navigator.navigateUp() },
            onCopy = { label, value ->
                scope.launch {
                    clipboard.setClipEntry(ClipEntry(ClipData.newPlainText(label, value)))
                    // Android 13 shows its own confirmation; below it there is none.
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) notice.show("$label copied")
                }
            },
            onRefresh = {
                scope.launch {
                    refreshing = true
                    val result = app.jobStore.refresh(jobId, app.session, System.currentTimeMillis())
                    refreshing = false
                    if (result != null) notice.show(result.label())
                }
            },
            refreshing = refreshing,
            // Computed here: `sample-ui` reads no host's BuildConfig.
            showProbes = BuildConfig.DEBUG || app.launchArgs.probes,
        )
        // Only a processing row can change. Keyed on the id, not the job: keying on the row would loop off its own write.
        // Waits for Room's first emission, so a cold-start deep link cannot read an empty list and skip.
        LaunchedEffect(jobId) {
            val jobs = snapshotFlow { app.jobs }.first { it != null } ?: return@LaunchedEffect
            if (jobs.firstOrNull { it.id == jobId }?.status != UseSmileIDSampleStatus.Processing) {
                return@LaunchedEffect
            }
            refreshing = true
            // Silent unless something happened: "still processing" on every visit is noise.
            val result = app.jobStore.refresh(jobId, app.session, System.currentTimeMillis())
            refreshing = false
            if (result != null && result !is UseSmileIDSampleStatusRefresh.StillProcessing) notice.show(result.label())
        }

        UseSmileIDSampleTransientNoticeHost(
            state = notice,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = SmileDimens.spacingMd, vertical = SmileDimens.spacingMd),
        )
    }
}

/** One line per outcome: a refresh that changed nothing still has to say so. */
private fun UseSmileIDSampleStatusRefresh.label(): String = when (this) {
    is UseSmileIDSampleStatusRefresh.Updated -> "${status.label} — $message"
    UseSmileIDSampleStatusRefresh.StillProcessing -> "Still processing"
    UseSmileIDSampleStatusRefresh.NoSession -> "Scan a token first"
    UseSmileIDSampleStatusRefresh.NoServerJob -> "Not submitted under a scanned token"
    UseSmileIDSampleStatusRefresh.PartnerMismatch -> "Submitted by a different partner"
    is UseSmileIDSampleStatusRefresh.Failed -> "Could not check status: $reason"
}
