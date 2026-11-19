package com.usesmileid.sampleapps.ui

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorAction
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorMessage
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleErrorResolution
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleTransportFailure
import com.usesmileid.sampleapps.ui.state.TokenJson
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleErrorHandling
import com.usesmileid.sampleapps.ui.state.parseTokenJson
import com.usesmileid.sampleapps.ui.state.string
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** spec/error-handling.json: the message and the one action every failure resolves to. */
class UseSmileIDSampleErrorHandlingSpecTest {

    private val file = parseTokenJson(spec("error-handling.json")) as TokenJson.Obj
    private val actions = file.section("actions")
    private val submission = file.list("submission")
    private val result = file.list("result")
    private val fallback = file.section("fallback")
    private val unexplained = file.section("unexplained")
    private val strings = parseTokenJson(spec("l10n/app/en.json")) as TokenJson.Obj

    /** A resolution as the spec states one: keys and ids, with the action's limit where the row has none. */
    private data class Expected(
        val id: String,
        val message: String,
        val action: String,
        val backoffSeconds: List<Int>,
        val maxUses: Int?,
        val waitsFor: String?,
    )

    private fun TokenJson.Obj.expected() = Expected(
        id = text("id"),
        message = text("message"),
        action = text("action"),
        backoffSeconds = ints("backoffSeconds"),
        maxUses = int("maxUses") ?: actions.section(text("action")).int("maxUses"),
        waitsFor = string("waitsFor"),
    )

    private fun UseSmileIDSampleErrorResolution.stated() = Expected(
        id = id,
        message = message.key,
        action = action.id,
        backoffSeconds = backoffSeconds,
        maxUses = maxUses,
        waitsFor = if (waitsForConnection) "connection" else null,
    )

    private fun row(id: String) = (submission + result).first { it.text("id") == id }.expected()

    private fun transport(id: String) = UseSmileIDSampleTransportFailure.entries.first { it.id == id }

    @Test
    fun the_table_holds_the_specs_rows_in_order() {
        assertEquals(submission.map { it.text("id") }, UseSmileIDSampleErrorHandling.submission.map { it.id })
        assertEquals(result.map { it.text("id") }, UseSmileIDSampleErrorHandling.result.map { it.id })
    }

    @Test
    fun every_row_resolves_to_its_message_action_and_limits() {
        submission.forEach { row ->
            val text = row.strings("serverMessageContains").firstOrNull()
            row.ints("status").forEach { status ->
                assertEquals("$status '$text'", row.expected(), UseSmileIDSampleErrorHandling.forStatus(status, text).stated())
            }
            row.string("transport")?.let { assertEquals(it, row.expected(), UseSmileIDSampleErrorHandling.forTransport(transport(it)).stated()) }
        }
        result.forEach { row ->
            val text = row.strings("serverMessageContains").firstOrNull()
            row.strings("reasons").forEach { reason ->
                assertEquals("$reason '$text'", row.expected(), UseSmileIDSampleErrorHandling.forReason(reason, text).stated())
            }
        }
    }

    @Test
    fun every_case_resolves_as_the_spec_says() {
        val cases = file.cases()
        assertTrue(cases.isNotEmpty())
        cases.forEach { case ->
            val text = case.string("serverMessage")
            val status = case.int("status")
            val transport = case.string("transport")
            val resolved = when {
                status != null -> UseSmileIDSampleErrorHandling.forStatus(status, text)
                transport != null -> UseSmileIDSampleErrorHandling.forTransport(transport(transport))
                else -> UseSmileIDSampleErrorHandling.forReason(case.string("reason"), text)
            }
            assertEquals("${status ?: transport ?: case.string("reason")} '$text'", case.text("resolves"), resolved.id)
        }
    }

    @Test
    fun a_failure_the_table_does_not_name_resolves_as_the_fallback() {
        assertEquals(row(fallback.text("submission")), UseSmileIDSampleErrorHandling.forStatus(599).stated())
        assertEquals(row(fallback.text("result")), UseSmileIDSampleErrorHandling.forReason("not_in_the_table").stated())
        assertEquals(row(fallback.text("result")), UseSmileIDSampleErrorHandling.forReason(null).stated())
    }

    @Test
    fun a_run_that_ended_early_resolves_as_the_unexplained_row() {
        assertEquals(unexplained.expected(), UseSmileIDSampleErrorHandling.unexplained.stated())
        assertEquals(UseSmileIDSampleErrorHandling.unexplained, UseSmileIDSampleErrorHandling.resolution(unexplained.text("id")))
    }

    @Test
    fun every_fraud_and_compliance_outcome_shows_the_one_message() {
        val reasons = result.first { it.text("id") == "notVerified" }.strings("reasons")
        assertTrue(reasons.size > 1)
        reasons.forEach { reason ->
            val resolved = UseSmileIDSampleErrorHandling.forReason(reason, "Verification failed: $reason")
            assertEquals(reason, UseSmileIDSampleErrorMessage.NotVerified, resolved.message)
            assertEquals(reason, UseSmileIDSampleErrorAction.Exit, resolved.action)
        }
        assertEquals("We couldn't verify your identity.", strings.text(UseSmileIDSampleErrorMessage.NotVerified.key))
    }

    @Test
    fun the_actions_are_the_specs_with_its_buttons_and_limits() {
        assertEquals(actions.members.keys.toList(), UseSmileIDSampleErrorAction.entries.map { it.id })
        UseSmileIDSampleErrorAction.entries.forEach { action ->
            val stated = actions.section(action.id)
            assertEquals(action.id, stated.text("button"), action.buttonKey)
            assertEquals(action.id, stated.int("maxUses"), action.maxUses)
        }
    }

    @Test
    fun every_message_and_button_has_a_string() {
        val used = (submission + result + unexplained).map { it.text("message") }.toSet()
        assertEquals(used, UseSmileIDSampleErrorMessage.entries.map { it.key }.toSet())
        (used + UseSmileIDSampleErrorAction.entries.map { it.buttonKey }).forEach { key ->
            assertTrue(key, strings.string(key)?.isNotBlank() == true)
        }
    }
}

private fun TokenJson.Obj.int(key: String): Int? = (members[key] as? TokenJson.Num)?.literal?.toInt()

private fun TokenJson.Obj.ints(key: String): List<Int> =
    (members[key] as? TokenJson.Arr)?.items.orEmpty().map { (it as TokenJson.Num).literal.toInt() }

private fun TokenJson.Obj.strings(key: String): List<String> = (members[key] as? TokenJson.Arr)?.strings().orEmpty()
