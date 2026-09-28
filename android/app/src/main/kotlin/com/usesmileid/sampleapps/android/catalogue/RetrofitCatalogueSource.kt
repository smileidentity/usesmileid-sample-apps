package com.usesmileid.sampleapps.android.catalogue

import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleCatalogueSource
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.http.GET
import retrofit2.http.Query
import java.io.IOException

/** The two unauthenticated catalogue endpoints. No token is sent: both are the same for every partner. */
interface UseSmileIDSampleCatalogueApi {

    @GET("v3/services/supported_id_types")
    suspend fun supportedIdTypes(): Response<ResponseBody>

    @GET("v3/services/supported_documents")
    suspend fun supportedDocuments(
        @Query("continent") continent: String,
        @Query("locale") locale: String,
    ): Response<ResponseBody>

    companion object {
        /** One per environment, built once, as the status API is. */
        fun of(environment: UseSmileIDSampleEnvironment): UseSmileIDSampleCatalogueApi = when (environment) {
            UseSmileIDSampleEnvironment.Sandbox -> sandboxApi
            UseSmileIDSampleEnvironment.Production -> productionApi
        }

        private val sandboxApi by lazy { build(UseSmileIDSampleEnvironment.Sandbox.baseUrl) }
        private val productionApi by lazy { build(UseSmileIDSampleEnvironment.Production.baseUrl) }

        private fun build(baseUrl: String): UseSmileIDSampleCatalogueApi = Retrofit.Builder()
            .baseUrl(baseUrl)
            .build()
            .create(UseSmileIDSampleCatalogueApi::class.java)
    }
}

/** Retrofit stays in the shell: the library defines the seam and decodes the body, this adapter fetches it. */
class RetrofitCatalogueSource : UseSmileIDSampleCatalogueSource {

    override suspend fun supportedIdTypes(environment: UseSmileIDSampleEnvironment): String =
        UseSmileIDSampleCatalogueApi.of(environment).supportedIdTypes().bodyOrThrow()

    override suspend fun supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String): String =
        UseSmileIDSampleCatalogueApi.of(environment).supportedDocuments(CONTINENT, locale).bodyOrThrow()

    private fun Response<ResponseBody>.bodyOrThrow(): String {
        val body = body()
        if (!isSuccessful || body == null) throw IOException("HTTP ${code()}")
        return body.use { it.string() }
    }

    private companion object {
        // The picker lists African countries only; the API's continent filter is how it asks for them.
        const val CONTINENT = "AFRICA"
    }
}
