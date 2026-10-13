package com.usesmileid.sampleapps.android.extension

import com.usesmileid.sampleapps.android.testSession
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenSession
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class UseSmileIDSampleLaunchSessionTest {
    private val linked = mutableListOf<UseSmileIDSampleTokenSession>()

    @Test
    fun links_the_session_the_extension_offers_at_launch() = runBlocking {
        val session = testSession()
        val returned = linkLaunchSession(object : UseSmileIDSampleShellExtension {
            override fun launchSession() = session
        }) { linked += it }
        assertEquals(listOf(session), linked)
        assertEquals(session, returned)
    }

    @Test
    fun links_nothing_without_an_extension_or_when_it_offers_none() = runBlocking {
        linkLaunchSession(null) { linked += it }
        linkLaunchSession(object : UseSmileIDSampleShellExtension {}) { linked += it }
        assertTrue(linked.isEmpty())
    }

    @Test
    fun a_failed_link_only_skips_the_launch_session() = runBlocking {
        linkLaunchSession(object : UseSmileIDSampleShellExtension {
            override fun launchSession() = testSession()
        }) { error("secure storage refused the write") }.let { assertEquals(null, it) }
    }

    @Test
    fun an_extension_that_fails_to_offer_a_session_only_skips_it() = runBlocking {
        linkLaunchSession(object : UseSmileIDSampleShellExtension {
            override fun launchSession(): UseSmileIDSampleTokenSession = error("no session to offer")
        }) { linked += it }
        assertTrue(linked.isEmpty())
    }
}
