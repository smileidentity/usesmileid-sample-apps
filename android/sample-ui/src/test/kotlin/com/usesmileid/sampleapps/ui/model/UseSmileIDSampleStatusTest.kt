package com.usesmileid.sampleapps.ui.model

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.v2.runComposeUiTest
import com.smileid.designsystem.smileSoftBadgeFills
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleJobStore
import com.usesmileid.sampleapps.ui.data.toEntity
import com.usesmileid.sampleapps.ui.data.toJob
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.label
import com.usesmileid.sampleapps.ui.labelRes
import com.usesmileid.sampleapps.ui.theme.darkColors
import com.usesmileid.sampleapps.ui.theme.lightColors
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Every job status, one table each: its label, its stored id and its round trip through the job table. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK])
@OptIn(ExperimentalTestApi::class)
class UseSmileIDSampleStatusTest {

    private val labels = listOf("Clear", "Attention", "Blocked", "Error", "Processing")

    @Test
    fun `each status reads in Title case, in composition and from resources`() {
        val (composed, resolved) = read {
            val resources = LocalContext.current.resources
            UseSmileIDSampleStatus.entries.map { it.label() } to
                UseSmileIDSampleStatus.entries.map { resources.getString(it.labelRes) }
        }
        assertEquals(labels, composed)
        assertEquals(labels, resolved)
    }

    @Test
    fun `each status is stored by name and reads back as itself`() {
        val job = UseSmileIDSampleJobStore.fixtures(0L).first()
        UseSmileIDSampleStatus.entries.forEach { status ->
            val entity = job.copy(status = status).toEntity()
            assertEquals(status.name, entity.statusId)
            assertEquals(status, entity.toJob().status)
        }
    }

    @Test
    fun `each status's pill is its role's soft fill, the same in both schemes`() {
        listOf(lightColors.badge, darkColors.badge).forEach { badge ->
            assertEquals(
                listOf("success", "warning", "error", "neutral", "info").map { smileSoftBadgeFills.getValue(it) }
                    .flatMap { listOf(it.background, it.text) },
                listOf(
                    badge.successBackground, badge.successText,
                    badge.warningBackground, badge.warningText,
                    badge.errorBackground, badge.errorText,
                    badge.neutralBackground, badge.neutralText,
                    badge.infoBackground, badge.infoText,
                ),
            )
        }
    }

    @Test
    fun `a stored id no status has reads back as Processing`() {
        val entity = UseSmileIDSampleJobStore.fixtures(0L).first().toEntity().copy(statusId = "Quarantined")
        assertEquals(UseSmileIDSampleStatus.Processing, entity.toJob().status)
    }

    private fun <T> read(block: @Composable () -> T): T {
        var value: T? = null
        runComposeUiTest {
            setContent { value = block() }
            waitForIdle()
        }
        @Suppress("UNCHECKED_CAST")
        return value as T
    }
}
