package com.usesmileid.sampleapps.ui.data

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.test.core.app.ApplicationProvider
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenBindings
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import java.io.File
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Retiring a session is the one place a token is deleted, and the security property worth pinning is
 * asymmetric: the credential must go, and the fact of the session must stay. A store that dropped
 * both would silently take the expiry banner and the scanner redirect with it.
 */
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
        store = UseSmileIDSampleStore(prefs)
    }

    @After
    fun tearDown() {
        file.delete()
    }

    @Test
    fun `retiring deletes the token and keeps only the handle and the deadline`() = runTest {
        store.linkTokenSession(session())
        assertNotNull("linking must store the token", store.tokenSession.first())
        assertNull("a fresh session is not an ended one", store.endedSession.first())

        store.retireTokenSession(session())

        assertNull("the credential must be gone", store.tokenSession.first())
        val ended = store.endedSession.first()
        assertEquals(HANDLE, ended?.id)
        assertEquals(EXPIRES_AT, ended?.endedAtMillis)
    }

    @Test
    fun `linking again clears the ended marker, so a live token is never shown as ended`() = runTest {
        store.retireTokenSession(session())
        assertNotNull(store.endedSession.first())

        store.linkTokenSession(session())

        assertNull("relinking must retire the marker too", store.endedSession.first())
        assertNotNull(store.tokenSession.first())
    }

    @Test
    fun `retiring twice is idempotent, because a lapse can be noticed more than once`() = runTest {
        store.linkTokenSession(session())
        store.retireTokenSession(session())
        store.retireTokenSession(session())

        assertNull(store.tokenSession.first())
        assertEquals(HANDLE, store.endedSession.first()?.id)
    }

    @Test
    fun `nothing stored reads as neither live nor ended`() = runTest {
        assertNull(store.tokenSession.first())
        assertNull(store.endedSession.first())
    }

    private fun session() = UseSmileIDSampleTokenSession(
        id = HANDLE,
        // Three dot-separated segments, so the decoder reads it back as a session.
        token = TOKEN,
        issuedAtMillis = EXPIRES_AT - 900_000,
        expiresAtMillis = EXPIRES_AT,
        bindings = UseSmileIDSampleTokenBindings(),
    )

    private companion object {
        const val HANDLE = "9f3a2c71"
        const val EXPIRES_AT = 1_760_000_900_000L

        /** Synthetic and unsigned: the decoder parses a token, it never verifies one. */
        val TOKEN = listOf(
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "eyJpYXQiOjE3NjAwMDAwMDAsImV4cCI6MTc2MDAwMDkwMH0",
            "not-a-signature",
        ).joinToString(".")
    }
}
