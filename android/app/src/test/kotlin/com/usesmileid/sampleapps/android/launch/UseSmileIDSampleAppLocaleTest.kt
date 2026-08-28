package com.usesmileid.sampleapps.android.launch

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The parse, not the composition: an unusable tag must be refused rather than applied as "undefined". */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class UseSmileIDSampleAppLocaleTest {

    @Test
    fun `a BCP 47 tag resolves to that locale`() {
        assertEquals("fr-FR", useSmileIDSampleLocales("fr-FR")?.toLanguageTags())
    }

    @Test
    fun `a language-only tag resolves`() {
        assertEquals("sw", useSmileIDSampleLocales("sw")?.toLanguageTags())
    }

    /** `Locale.forLanguageTag` answers junk with an undefined locale, which would silently render the default. */
    @Test
    fun `a tag naming no language is refused`() {
        assertNull(useSmileIDSampleLocales("not a tag"))
        assertNull(useSmileIDSampleLocales(""))
    }

    /** A list is legal input, so one bad entry must not be applied alongside a good one. */
    @Test
    fun `a list is kept in order and refused when any entry names no language`() {
        assertEquals("fr-FR,en-GB", useSmileIDSampleLocales("fr-FR,en-GB")?.toLanguageTags())
        assertNull(useSmileIDSampleLocales("fr-FR,%%%"))
    }
}
