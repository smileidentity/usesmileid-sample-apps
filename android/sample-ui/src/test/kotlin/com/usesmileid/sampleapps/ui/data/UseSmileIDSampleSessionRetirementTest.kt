package com.usesmileid.sampleapps.ui.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.test.core.app.ApplicationProvider
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import java.io.File
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK])
class UseSmileIDSampleSessionRetirementTest {

    private lateinit var file: File
    private lateinit var prefs: DataStore<Preferences>
    private lateinit var store: UseSmileIDSampleStore

    @Before
    fun setUp() {
        file = File.createTempFile("retirement", ".preferences_pb").also { it.delete() }
        prefs = PreferenceDataStoreFactory.create { file }
        store = UseSmileIDSampleStore(prefs, UseSmileIDSampleTestCipher)
    }

    @After
    fun tearDown() {
        file.delete()
    }

    @Test
    fun `retiring deletes the token and keeps only the handle and the deadline`() = runTest {
        store.linkTokenSession(session())
        assertNotNull("linking must store the token", store.session.first().live)
        assertNull("a fresh session is not an ended one", store.session.first().ended)

        store.retireTokenSession(session())

        assertNull("the credential must be gone", store.session.first().live)
        val ended = store.session.first().ended
        assertEquals(HANDLE, ended?.id)
        assertEquals(EXPIRES_AT, ended?.endedAtMillis)
    }

    @Test
    fun `linking again clears the ended marker, so a live token is never shown as ended`() = runTest {
        store.retireTokenSession(session())
        assertNotNull(store.session.first().ended)

        store.linkTokenSession(session())

        assertNull("relinking must retire the marker too", store.session.first().ended)
        assertNotNull(store.session.first().live)
    }

    @Test
    fun `retiring twice is idempotent, because a lapse can be noticed more than once`() = runTest {
        store.linkTokenSession(session())
        store.retireTokenSession(session())
        store.retireTokenSession(session())

        assertNull(store.session.first().live)
        assertEquals(HANDLE, store.session.first().ended?.id)
    }

    @Test
    fun `the live half and the ended half always come from the same write`() = runTest {
        store.linkTokenSession(session())
        store.session.first().let { record ->
            assertNotNull(record.live)
            assertNull("a live token and an ended marker must never both be set", record.ended)
        }

        store.retireTokenSession(session())
        store.session.first().let { record ->
            assertNull(record.live)
            assertNotNull("retiring must leave exactly the marker", record.ended)
        }
    }

    @Test
    fun `nothing stored reads as neither live nor ended`() = runTest {
        assertNull(store.session.first().live)
        assertNull(store.session.first().ended)
    }

    @Test
    fun `the stored token is sealed, never the credential in plain text`() = runTest {
        store.linkTokenSession(session())

        val stored = prefs.data.first()[SESSION_TOKEN]
        assertNotNull(stored)
        assertTrue("the token reached disk in plain text", stored != TOKEN && !stored!!.contains(TOKEN))
        assertEquals(TOKEN, store.session.first().live?.token)
    }

    @Test
    fun `a plain token written before sealing still reads, so an upgrade keeps its session`() = runTest {
        prefs.edit { it[SESSION_TOKEN] = TOKEN }

        assertEquals(TOKEN, store.session.first().live?.token)
    }

    private fun session() = UseSmileIDSampleTokenSession(
        id = HANDLE,
        token = TOKEN,
        issuedAtMillis = EXPIRES_AT - 900_000,
        expiresAtMillis = EXPIRES_AT,
        bindings = UseSmileIDSampleTokenBindings(),
        environment = UseSmileIDSampleEnvironment.Sandbox,
    )

    private companion object {
        const val HANDLE = "9f3a2c71"
        const val EXPIRES_AT = 1_760_000_900_000L
        val SESSION_TOKEN = stringPreferencesKey("token_session_token")

        /** Synthetic and unsigned: the decoder parses a token, never verifies one. */
        val TOKEN = listOf(
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            // {"iat":1760000000,"exp":1760000900,"api_url":"https://testapi.smileidentity.com/v3"}
            "eyJpYXQiOjE3NjAwMDAwMDAsImV4cCI6MTc2MDAwMDkwMCwiYXBpX3VybCI6Imh0dHBzOi8vdGVzdGFwaS5zbWlsZWlkZW50aXR5LmNvbS92MyJ9",
            "not-a-signature",
        ).joinToString(".")
    }
}
