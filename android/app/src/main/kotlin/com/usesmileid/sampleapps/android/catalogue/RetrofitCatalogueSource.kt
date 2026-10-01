package com.usesmileid.sampleapps.android.catalogue

import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleCatalogueHttpException
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleCatalogueSource
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.http.GET
import retrofit2.http.Header
import retrofit2.http.Query

/** The two unauthenticated catalogue endpoints, the same for every partner, and the partner's own configuration under its token. */
interface UseSmileIDSampleCatalogueApi {

    @GET("v3/services/supported_id_types")
    suspend fun supportedIdTypes(): Response<ResponseBody>

    @GET("v3/services/supported_documents")
    suspend fun supportedDocuments(@Query("locale") locale: String): Response<ResponseBody>

    @GET("v3/services/config")
    suspend fun servicesConfig(
        @Header("SmileID-Token") token: String,
        @Query("product") product: String,
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
        UseSmileIDSampleCatalogueApi.of(environment).supportedDocuments(locale).bodyOrThrow()

    override suspend fun servicesConfig(environment: UseSmileIDSampleEnvironment, token: String, locale: String): String =
        UseSmileIDSampleCatalogueApi.of(environment)
            .servicesConfig(token, UseSmileIDSampleCatalogueJson.ENHANCED_DOCUMENT_VERIFICATION, locale)
            .bodyOrThrow()

    private fun Response<ResponseBody>.bodyOrThrow(): String {
        val body = body()
        if (!isSuccessful || body == null) {
            errorBody()?.close()
            throw UseSmileIDSampleCatalogueHttpException(code())
        }
        return body.use { it.string() }
    }
}
