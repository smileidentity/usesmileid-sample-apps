package com.usesmileid.sampleapps.android.status

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
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

/** `GET /v3/status/{jobId}` — the partner's own call: the SDK stops at the 202 that creates the job. */
interface UseSmileIDSampleStatusApi {

    @GET("v3/status/{jobId}")
    suspend fun status(
        @Path("jobId") jobId: String,
        /** The session's own JWT from `POST /v3/token`. Never logged. */
        @Header("SmileID-Token") token: String,
    ): Response<UseSmileIDSampleStatusResponse>

    companion object {
        /** One per environment, built once: Retrofit makes its own OkHttp client, so per-request was a pool per pull. */
        fun of(sandbox: Boolean): UseSmileIDSampleStatusApi = if (sandbox) sandboxApi else productionApi

        private val sandboxApi: UseSmileIDSampleStatusApi by lazy {
            build(UseSmileIDSampleEnvironment.Sandbox.baseUrl)
        }
        private val productionApi: UseSmileIDSampleStatusApi by lazy {
            build(UseSmileIDSampleEnvironment.Production.baseUrl)
        }

        private fun build(baseUrl: String): UseSmileIDSampleStatusApi = Retrofit.Builder()
            .baseUrl(baseUrl)
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
