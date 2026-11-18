package com.usesmileid.sampleapps.ui.state

import com.usesmileid.core.exception.NetworkServerException
import com.usesmileid.core.exception.NetworkTimeoutException
import com.usesmileid.core.exception.NetworkTransportException
import com.usesmileid.core.exception.UseSmileIDErrorCode
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorResolution
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleTransportFailure

/** The row a failure the SDK hands `onResult` resolves to; null when no submission returned it, such as a camera that could not start. */
fun Throwable.errorResolution(): UseSmileIDSampleErrorResolution? = when (this) {
    is NetworkServerException -> UseSmileIDSampleErrorHandling.forStatus(statusCode, message)
    is NetworkTimeoutException -> UseSmileIDSampleErrorHandling.forTransport(UseSmileIDSampleTransportFailure.Timeout)
    is NetworkTransportException ->
        UseSmileIDSampleErrorHandling.forTransport(UseSmileIDSampleTransportFailure.NoConnection)
            .takeIf { errorCode == UseSmileIDErrorCode.Network.ConnectionFailed }
    else -> null
}
