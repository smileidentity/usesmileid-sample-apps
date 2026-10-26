package com.usesmileid.sampleapps.android

import com.usesmileid.core.models.JobType
import com.usesmileid.core.models.UseSmileIDResult
import com.usesmileid.data.model.CapturedJob
import com.usesmileid.sampleapps.android.flow.deleteFiles
import com.usesmileid.sampleapps.android.flow.recordResult
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleFlowStatus
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleFlowResult
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/** What the result card records for each terminal result, and what the sample does with a captured job. */
class SdkFlowResultTest {

    @get:Rule
    val folder = TemporaryFolder()

    @Test
    fun `a captured job is recorded as captured, not as a failure`() {
        val flowResult = UseSmileIDSampleFlowResult()

        recordResult(flowResult, UseSmileIDResult.Captured(capturedJob(folder.newFolder("session"))))

        assertEquals(UseSmileIDSampleFlowStatus.Captured, flowResult.status)
        assertNull(flowResult.lastError)
        assertNull("nothing was submitted, so there is no job id", flowResult.jobId)
        assertEquals(1, flowResult.resultCallbackCount)
    }

    @Test
    fun `a captured job's files and session directory are deleted, since this sample forwards nothing`() {
        val session = folder.newFolder("session")
        val selfie = File(session, "selfie.jpg").apply { writeText("selfie") }
        val liveness = File(session, "liveness.jpg").apply { writeText("liveness") }
        File(session, "left-over.json").writeText("{}")
        val front = folder.newFile("front.jpg").apply { writeText("front") }

        capturedJob(session, selfie = selfie, liveness = listOf(liveness), front = front).deleteFiles()

        assertFalse(session.exists())
        assertFalse("a listed file outside the session directory goes too", front.exists())
    }

    private fun capturedJob(
        session: File,
        selfie: File? = null,
        liveness: List<File> = emptyList(),
        front: File? = null,
    ) = CapturedJob(
        jobType = JobType.SmartSelfieEnrollment,
        sessionId = "session",
        sessionDirectory = session,
        selfieImage = selfie,
        livenessImages = liveness,
        frontDocument = front,
        backDocument = null,
        visaDocument = null,
        headers = emptyMap(),
        encryptedPackage = "00",
        packageNonce = "00",
        packageTag = "00",
    )
}
