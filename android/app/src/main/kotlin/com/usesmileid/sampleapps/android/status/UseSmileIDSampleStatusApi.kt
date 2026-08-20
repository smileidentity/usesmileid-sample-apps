package com.usesmileid.sampleapps.android.status

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Path

/**
 * `GET /v3/status/{jobId}` — the partner's own call, not the SDK's. The SDK owns capture and
 * submission and stops at the 202 that creates the job; asking what became of it afterwards is the
 * host's job, which is exactly what this sample is here to show.
 *
 * The HTTP code carries the same information as the body's `status`, so both are read: **200** is a
 * terminal state, **202** is still processing, **404** is a job this token cannot see.
 */
interface UseSmileIDSampleStatusApi {

    @GET("v3/status/{jobId}")
    suspend fun status(
        @Path("jobId") jobId: String,
        /** The session's own JWT, minted by `POST /v3/token`. Never logged. */
        @Header("SmileID-Token") token: String,
    ): Response<UseSmileIDSampleStatusResponse>

    companion object {
        /** Sandbox and production, as `spec/` and the SDK both name them. */
        private const val SANDBOX_URL = "https://testapi.smileidentity.com/"
        private const val PRODUCTION_URL = "https://api.smileidentity.com/"

        fun of(sandbox: Boolean): UseSmileIDSampleStatusApi = Retrofit.Builder()
            .baseUrl(if (sandbox) SANDBOX_URL else PRODUCTION_URL)
            // Unknown keys ignored: a field added server-side must not turn a good response into a crash.
            .addConverterFactory(Json { ignoreUnknownKeys = true }.asConverterFactory(JSON_MEDIA_TYPE))
            .build()
            .create(UseSmileIDSampleStatusApi::class.java)

        private val JSON_MEDIA_TYPE = "application/json".toMediaType()
    }
}

@Serializable
data class UseSmileIDSampleStatusResponse(
    val status: String,
    @SerialName("job_id") val jobId: String,
    @SerialName("user_id") val userId: String,
    val message: String,
    @SerialName("created_at") val createdAt: String,
)
