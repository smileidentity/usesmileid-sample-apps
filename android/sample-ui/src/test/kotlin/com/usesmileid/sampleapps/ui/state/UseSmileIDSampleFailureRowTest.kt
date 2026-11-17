package com.usesmileid.sampleapps.ui.state

import com.usesmileid.core.exception.NetworkServerException
import com.usesmileid.core.exception.NetworkTimeoutException
import com.usesmileid.core.exception.NetworkTransportException
import com.usesmileid.core.exception.UseSmileIDErrorCode
import java.io.IOException
import java.net.SocketTimeoutException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** How a failure the SDK hands `onResult` picks its row of `spec/error-handling.json`. */
class UseSmileIDSampleFailureRowTest {

    @Test
    fun a_refused_submission_resolves_by_its_status() {
        assertEquals("rateLimited", NetworkServerException(statusCode = 429).errorResolution()?.id)
        assertEquals("serverError", NetworkServerException(statusCode = 503).errorResolution()?.id)
        assertEquals("notEnabled", NetworkServerException(statusCode = 403).errorResolution()?.id)
    }

    @Test
    fun the_servers_message_tells_rows_of_one_status_apart() {
        val idNumber = NetworkServerException(statusCode = 400, message = "Invalid ID number format for the specified country and ID type.")
        assertEquals("idNumberInvalid", idNumber.errorResolution()?.id)
        assertEquals("sdkVersionNotAllowed", NetworkServerException(statusCode = 403, message = "SDK version not allowed.").errorResolution()?.id)
        assertEquals("requestInvalid", NetworkServerException(statusCode = 400).errorResolution()?.id)
    }

    @Test
    fun a_timeout_and_a_lost_connection_resolve_as_transport_failures() {
        assertEquals("timeout", NetworkTimeoutException(SocketTimeoutException()).errorResolution()?.id)
        assertEquals("noConnection", NetworkTransportException(IOException()).errorResolution()?.id)
    }

    @Test
    fun a_transport_failure_that_would_fail_the_same_way_again_has_no_row() {
        val failsAgain = NetworkTransportException(IOException(), errorCode = UseSmileIDErrorCode.Network.RequestFailed)
        assertNull(failsAgain.errorResolution())
    }

    @Test
    fun a_failure_no_submission_returned_has_no_row() {
        assertNull(IllegalStateException("the camera could not start").errorResolution())
    }
}
