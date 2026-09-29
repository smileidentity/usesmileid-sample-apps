package com.usesmileid.sampleapps.ui.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiCountryDocuments
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleApiIdType
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueData
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueRules
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleKycIdType
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

    private var run: Run? = null
    private var idTypesJob: Job? = null
    private var documentsJob: Job? = null

    var idTypes: UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> by mutableStateOf(UseSmileIDSampleCatalogue.Loading)
        private set

    var documents: UseSmileIDSampleCatalogue<UseSmileIDSampleApiCountryDocuments> by
        mutableStateOf(UseSmileIDSampleCatalogue.Loading)
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

    /** Asks again for whichever list failed, under the same timing as the first attempt. */
    fun retry() {
        if (run == null) return
        if (idTypes is UseSmileIDSampleCatalogue.Failed) fetchIdTypes()
        if (documents is UseSmileIDSampleCatalogue.Failed) fetchDocuments()
    }

    /** Leaving the form: anything in flight is cancelled and the next run starts clean. */
    fun stop() {
        idTypesJob?.cancel()
        documentsJob?.cancel()
        run = null
        idTypes = UseSmileIDSampleCatalogue.Loading
        documents = UseSmileIDSampleCatalogue.Loading
    }

    fun countries(family: UseSmileIDSampleCatalogueFamily): UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> {
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

    fun documents(country: String): UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> =
        when (val docs = documents) {
            is UseSmileIDSampleCatalogue.Ready -> ready(UseSmileIDSampleCatalogueRules.documents(docs.items, country))
            else -> docs.withoutItems()
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
        // Decoded off the main thread: the whole continent is about 45 KB, which a sheet would feel.
        val items = withTimeout(timeout) { withContext(decoder) { fetch() } }
        if (items == null) UseSmileIDSampleCatalogue.Failed("Unreadable response") else UseSmileIDSampleCatalogue.Ready(items)
    } catch (timedOut: TimeoutCancellationException) {
        UseSmileIDSampleCatalogue.Failed("Timed out after $timeout")
    } catch (cancelled: CancellationException) {
        throw cancelled
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
