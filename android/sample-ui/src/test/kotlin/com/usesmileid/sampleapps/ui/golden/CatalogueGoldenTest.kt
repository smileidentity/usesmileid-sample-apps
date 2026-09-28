package com.usesmileid.sampleapps.ui.golden

import android.provider.Settings
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.usesmileid.sampleapps.ui.CatalogueFixtures
import com.usesmileid.sampleapps.ui.screens.CaptureAsSheet
import com.usesmileid.sampleapps.ui.screens.CaptureModeSheet
import com.usesmileid.sampleapps.ui.screens.CountryPickerSheet
import com.usesmileid.sampleapps.ui.screens.GenericDocumentSheet
import com.usesmileid.sampleapps.ui.screens.DocumentPickerSheet
import com.usesmileid.sampleapps.ui.screens.IdTypePickerSheet
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureMode
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogue
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCatalogueFamily
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCountry
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleGenericDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocument
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleKycIdType
import org.junit.Before
import org.junit.Test
import org.robolectric.RuntimeEnvironment

/** The fetching sheets while loading, failed and empty, and the three sheets the document features add. */
class CatalogueGoldenTest : GoldenTest() {

    /** A pulsing skeleton never lets the test idle, so these record the reduced-motion rows the platform also draws. */
    @Before
    fun reduceMotion() {
        Settings.Global.putFloat(
            RuntimeEnvironment.getApplication().contentResolver,
            Settings.Global.ANIMATOR_DURATION_SCALE,
            0f,
        )
    }

    @Test
    fun country_picker_loading() = goldens("sheet_country_picker_loading", fullWindow = true) {
        Country(UseSmileIDSampleCatalogue.Loading)
    }

    @Test
    fun country_picker_error() = goldens("sheet_country_picker_error", fullWindow = true) {
        Country(UseSmileIDSampleCatalogue.Failed("offline"))
    }

    /** A search that matched nothing, which needs no advice: the reader typed the query. */
    @Test
    fun country_picker_empty() = goldens("sheet_country_picker_empty", fullWindow = true) {
        Country(UseSmileIDSampleCatalogue.Ready(CatalogueFixtures.countries(UseSmileIDSampleCatalogueFamily.Kyc)), query = "Atlantis")
    }

    @Test
    fun country_picker_error_max_font_scale() = assertSurvivesMaxFontScale { Country(UseSmileIDSampleCatalogue.Failed("offline")) }

    @Test
    fun id_type_picker_loading() = goldens("sheet_id_type_picker_loading", fullWindow = true) {
        IdType(UseSmileIDSampleCatalogue.Loading)
    }

    @Test
    fun id_type_picker_error() = goldens("sheet_id_type_picker_error", fullWindow = true) {
        IdType(UseSmileIDSampleCatalogue.Failed("offline"))
    }

    @Test
    fun id_type_picker_empty() = goldens("sheet_id_type_picker_empty", fullWindow = true) {
        IdType(UseSmileIDSampleCatalogue.Empty, country = UseSmileIDSampleCountry("RW", "Rwanda"))
    }

    @Test
    fun document_picker() = goldens("sheet_document_picker", fullWindow = true) {
        Document(UseSmileIDSampleCatalogue.Ready(CatalogueFixtures.documents("ZA")))
    }

    /** Only names are translated under ar-EG, and the app does not flip its own layout, so the rows stay left-to-right. */
    @Test
    fun document_picker_arabic_names() = goldens("sheet_document_picker_ar", fullWindow = true) {
        Document(UseSmileIDSampleCatalogue.Ready(ARABIC_DOCUMENTS), country = UseSmileIDSampleCountry("KE", "كينيا"))
    }

    @Test
    fun document_picker_loading() = goldens("sheet_document_picker_loading", fullWindow = true) {
        Document(UseSmileIDSampleCatalogue.Loading)
    }

    @Test
    fun document_picker_error() = goldens("sheet_document_picker_error", fullWindow = true) {
        Document(UseSmileIDSampleCatalogue.Failed("offline"))
    }

    @Test
    fun document_picker_empty() = goldens("sheet_document_picker_empty", fullWindow = true) {
        Document(UseSmileIDSampleCatalogue.Empty)
    }

    @Test
    fun capture_as_sheet() = goldens("sheet_capture_as", fullWindow = true) {
        CaptureAsSheet(selected = UseSmileIDSampleCaptureAs.GenericDocument, onSelect = {}, onDismissRequest = {})
    }

    @Test
    fun generic_document_sheet() = goldens("sheet_generic_document", fullWindow = true) {
        GenericDocumentSheet(initial = UseSmileIDSampleGenericDocument(), onDone = {}, onDismissRequest = {})
    }

    @Test
    fun generic_document_sheet_max_font_scale() = assertSurvivesMaxFontScale {
        GenericDocumentSheet(initial = UseSmileIDSampleGenericDocument(), onDone = {}, onDismissRequest = {})
    }

    @Test
    fun capture_mode_sheet() = goldens("sheet_capture_mode", fullWindow = true) {
        CaptureModeSheet(selected = UseSmileIDSampleCaptureMode.AutoWithFallback, onSelect = {}, onDismissRequest = {})
    }

    @Composable
    private fun Country(catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleCountry>, query: String = "") = Box(Modifier.fillMaxSize()) {
        CountryPickerSheet(
            catalogue = catalogue,
            selected = null,
            query = query,
            onQueryChange = {},
            onSelect = {},
            onRetry = {},
            onDismissRequest = {},
        )
    }

    @Composable
    private fun IdType(
        catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType>,
        country: UseSmileIDSampleCountry = CatalogueFixtures.kenya,
    ) = Box(Modifier.fillMaxSize()) {
        IdTypePickerSheet(
            country = country,
            catalogue = catalogue,
            selected = null,
            query = "",
            onQueryChange = {},
            onSelect = {},
            onRetry = {},
            onDismissRequest = {},
        )
    }

    @Composable
    private fun Document(
        catalogue: UseSmileIDSampleCatalogue<UseSmileIDSampleDocument>,
        country: UseSmileIDSampleCountry = CatalogueFixtures.southAfrica,
    ) = Box(Modifier.fillMaxSize()) {
        DocumentPickerSheet(
            country = country,
            catalogue = catalogue,
            selected = null,
            query = "",
            onQueryChange = {},
            onSelect = {},
            onRetry = {},
            onDismissRequest = {},
        )
    }

    private companion object {
        /** Names as the API returns them under ar-EG, codes unchanged (sandbox, 2026-09-28). */
        val ARABIC_DOCUMENTS = listOf(
            UseSmileIDSampleDocument(code = "ALIEN_CARD", name = "بطاقة الأجانب", hasBack = false, format = 1),
            UseSmileIDSampleDocument(code = "IDENTITY_CARD", name = "بطاقة الهوية", hasBack = true, format = 1),
            UseSmileIDSampleDocument(code = "PASSPORT", name = "جواز السفر", hasBack = false, format = 3),
        )
    }
}
