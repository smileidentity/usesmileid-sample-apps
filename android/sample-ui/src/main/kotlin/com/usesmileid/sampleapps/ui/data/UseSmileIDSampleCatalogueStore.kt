package com.usesmileid.sampleapps.ui.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiCountryDocuments
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiEnabledCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueData
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleKycIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** The ID form's lists for one run: fetched ahead, held in memory only, cancelled on leaving. */
class UseSmileIDSampleCatalogueStore(
    private val source: UseSmileIDSampleCatalogueSource,
    private val scope: CoroutineScope,
    private val timeout: Duration = 10.seconds,
    private val decoder: CoroutineDispatcher = Dispatchers.Default,
) {
    private data class Run(val environment: UseSmileIDSampleEnvironment, val locale: String)

    private data class EnabledKey(val sessionId: String?, val environment: UseSmileIDSampleEnvironment, val locale: String)

    private var run: Run? = null
    private var idTypesJob: Job? = null
    private var documentsJob: Job? = null
    private var enabledKey: EnabledKey? = null
    private var enabledToken: String = ""
    private var enabledJob: Job? = null

    var idTypes: UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> by mutableStateOf(UseSmileIDSampleCatalogue.Loading)
        private set

    var documents: UseSmileIDSampleCatalogue<UseSmileIDSampleApiCountryDocuments> by
        mutableStateOf(UseSmileIDSampleCatalogue.Loading)
        private set

    /** The partner's Enhanced Document Verification list, kept per session: only a relink or a locale change asks again. */
    var enabled: UseSmileIDSampleCatalogue<UseSmileIDSampleApiEnabledCountry> by mutableStateOf(UseSmileIDSampleCatalogue.Loading)
        private set

    /** A product tap: a new run always asks the server again, so a list changed on the server shows up. */
    fun begin(environment: UseSmileIDSampleEnvironment, locale: String) {
        stop()
        run = Run(environment, locale)
        fetchIdTypes()
        fetchDocuments()
    }

    /** The form itself: a deep link can land here without the product tap, so start only if nothing has. */
    fun ensure(environment: UseSmileIDSampleEnvironment, locale: String) {
        if (run != Run(environment, locale)) begin(environment, locale)
    }

    /** Enhanced Document Verification: fetches [session]'s list unless it is already here or on its way. */
    fun ensureEnabled(environment: UseSmileIDSampleEnvironment, locale: String, session: UseSmileIDSampleTokenSession?) {
        val key = EnabledKey(session?.id, environment, locale)
        if (key == enabledKey && (enabled is UseSmileIDSampleCatalogue.Ready || enabledJob?.isActive == true)) return
        if (session == null) {
            enabledJob?.cancel()
            enabledKey = null
            enabledToken = ""
            enabled = UseSmileIDSampleCatalogue.Failed("No session", UseSmileIDSampleCatalogueRules.advice(401))
            return
        }
        enabledKey = key
        enabledToken = session.token
        fetchEnabled()
    }

    /** Asks again for whichever list failed, under the same timing as the first attempt. */
    fun retry() {
        if (enabled is UseSmileIDSampleCatalogue.Failed) fetchEnabled()
        if (run == null) return
        if (idTypes is UseSmileIDSampleCatalogue.Failed) fetchIdTypes()
        if (documents is UseSmileIDSampleCatalogue.Failed) fetchDocuments()
    }

    /** Leaving the form: anything in flight is cancelled and the next run starts clean, bar a session's arrived list. */
    fun stop() {
        idTypesJob?.cancel()
        documentsJob?.cancel()
        run = null
        idTypes = UseSmileIDSampleCatalogue.Loading
        documents = UseSmileIDSampleCatalogue.Loading
        if (enabled !is UseSmileIDSampleCatalogue.Ready) {
            enabledJob?.cancel()
            enabledKey = null
            enabledToken = ""
            enabled = UseSmileIDSampleCatalogue.Loading
        }
    }

    /** [product] Enhanced Document Verification offers only the countries its partner enabled. */
    fun countries(
        family: UseSmileIDSampleCatalogueFamily,
        product: UseSmileIDSampleProduct? = null,
    ): UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> {
        if (product == UseSmileIDSampleProduct.EnhancedDocumentVerification) {
            return withEnabled { docs, enabled -> UseSmileIDSampleCatalogueRules.enabledCountries(docs, enabled) }
        }
        val docs = documents
        val types = if (family == UseSmileIDSampleCatalogueFamily.Kyc) idTypes else UseSmileIDSampleCatalogue.Ready(emptyList())
        return when {
            docs is UseSmileIDSampleCatalogue.Failed -> docs
            types is UseSmileIDSampleCatalogue.Failed -> types
            docs !is UseSmileIDSampleCatalogue.Ready || types !is UseSmileIDSampleCatalogue.Ready -> UseSmileIDSampleCatalogue.Loading
            else -> ready(UseSmileIDSampleCatalogueRules.countries(UseSmileIDSampleCatalogueData(types.items, docs.items), family))
        }
    }

    fun idTypes(country: String): UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType> =
        when (val types = idTypes) {
            is UseSmileIDSampleCatalogue.Ready -> ready(UseSmileIDSampleCatalogueRules.idTypes(types.items, country))
            else -> types.withoutItems()
        }

    fun documents(
        country: String,
        product: UseSmileIDSampleProduct = UseSmileIDSampleProduct.DocumentVerification,
    ): UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> =
        if (product == UseSmileIDSampleProduct.EnhancedDocumentVerification) {
            withEnabled { docs, enabled -> UseSmileIDSampleCatalogueRules.enabledDocuments(docs, enabled, country) }
        } else {
            plainDocuments(country, product)
        }

    private fun plainDocuments(country: String, product: UseSmileIDSampleProduct): UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> =
        when (val docs = documents) {
            is UseSmileIDSampleCatalogue.Ready -> ready(UseSmileIDSampleCatalogueRules.documents(docs.items, country, product))
            else -> docs.withoutItems()
        }

    private fun <T> withEnabled(
        rows: (List<UseSmileIDSampleApiCountryDocuments>, List<UseSmileIDSampleApiEnabledCountry>) -> List<T>,
    ): UseSmileIDSampleCatalogue<T> {
        val docs = documents
        val allowed = enabled
        return when {
            allowed is UseSmileIDSampleCatalogue.Failed -> allowed
            docs is UseSmileIDSampleCatalogue.Failed -> docs
            docs is UseSmileIDSampleCatalogue.Ready && allowed is UseSmileIDSampleCatalogue.Ready -> ready(rows(docs.items, allowed.items))
            else -> UseSmileIDSampleCatalogue.Loading
        }
    }

    private fun fetchEnabled() {
        val key = enabledKey ?: return
        val token = enabledToken
        enabledJob?.cancel()
        enabled = UseSmileIDSampleCatalogue.Loading
        enabledJob = scope.launch {
            enabled = load {
                UseSmileIDSampleCatalogueJson.enabledCountries(source.servicesConfig(key.environment, token, key.locale))
            }
        }
    }

    private fun fetchIdTypes() {
        val current = run ?: return
        idTypesJob?.cancel()
        idTypes = UseSmileIDSampleCatalogue.Loading
        idTypesJob = scope.launch {
            idTypes = load { UseSmileIDSampleCatalogueJson.idTypes(source.supportedIdTypes(current.environment)) }
        }
    }

    private fun fetchDocuments() {
        val current = run ?: return
        documentsJob?.cancel()
        documents = UseSmileIDSampleCatalogue.Loading
        documentsJob = scope.launch {
            documents = load {
                UseSmileIDSampleCatalogueJson.documents(source.supportedDocuments(current.environment, current.locale))
            }
        }
    }

    private suspend fun <T> load(fetch: suspend () -> List<T>?): UseSmileIDSampleCatalogue<T> = try {
        // Decoded off the main thread: the whole catalogue is about 200 KB, which a sheet would feel.
        val items = withTimeout(timeout) { withContext(decoder) { fetch() } }
        if (items == null) UseSmileIDSampleCatalogue.Failed("Unreadable response") else UseSmileIDSampleCatalogue.Ready(items)
    } catch (timedOut: TimeoutCancellationException) {
        UseSmileIDSampleCatalogue.Failed("Timed out after $timeout")
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (refused: UseSmileIDSampleCatalogueHttpException) {
        UseSmileIDSampleCatalogue.Failed(refused.message.orEmpty(), UseSmileIDSampleCatalogueRules.advice(refused.status))
    } catch (@Suppress("TooGenericExceptionCaught") failure: Exception) {
        UseSmileIDSampleCatalogue.Failed(failure.message ?: failure::class.java.simpleName)
    }

    private fun <T> ready(items: List<T>): UseSmileIDSampleCatalogue<T> =
        if (items.isEmpty()) UseSmileIDSampleCatalogue.Empty else UseSmileIDSampleCatalogue.Ready(items)

    private fun UseSmileIDSampleCatalogue<*>.withoutItems(): UseSmileIDSampleCatalogue<Nothing> = when (this) {
        is UseSmileIDSampleCatalogue.Failed -> this
        UseSmileIDSampleCatalogue.Empty -> UseSmileIDSampleCatalogue.Empty
        else -> UseSmileIDSampleCatalogue.Loading
    }
}
