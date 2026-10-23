package com.usesmileid.sampleapps.android.navigation

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.SavedStateHandle
import com.usesmileid.njia.NjiaEngine
import com.usesmileid.njia.NjiaEntry
import com.usesmileid.njia.NjiaIntent
import com.usesmileid.njia.NjiaKit
import com.usesmileid.njia.NjiaListener
import com.usesmileid.njia.decodeState
import com.usesmileid.njia.encodeState
import com.usesmileid.njia.navigator
import com.usesmileid.njia.select
import com.usesmileid.njia.stepOf
import com.usesmileid.njia.compose.NjiaStepScope
import com.usesmileid.njia.NjiaNavigator
import com.usesmileid.sampleapps.android.flow.UseSmileIDSampleRunEntry
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct

/** The shell's engine, over the app's own step kinds and facts. */
internal typealias UseSmileIDSampleEngine = NjiaEngine<UseSmileIDSampleStep, UseSmileIDSampleFact>

/** What each of the app's steps sees of the flow. */
internal typealias UseSmileIDSampleStepScope = NjiaStepScope<UseSmileIDSampleStep, UseSmileIDSampleFact>

/** Keeps the shell's engine across recreation, and its state in saved state so process death restores the stack. */
internal class UseSmileIDSampleNavigationModel(application: Application, private val saved: SavedStateHandle) :
    AndroidViewModel(application) {

    val graph = application.useSmileIDSampleNjiaGraph()

    /** Whether the engine came back from saved state, so the launching intent's link is not replayed over it. */
    val restored: Boolean = saved.contains(STATE)

    var engine: UseSmileIDSampleEngine by mutableStateOf(restoredEngine() ?: NjiaKit.start(graph))
        private set

    private val save = NjiaListener<UseSmileIDSampleFact> { saved[STATE] = UseSmileIDSampleNjiaCodec.encodeState(it.state) }

    init {
        watch(engine)
    }

    /** Opens [link] under [facts] as a new flow; a link the graph refuses leaves the current one. */
    fun open(link: String, facts: Set<UseSmileIDSampleFact>): Boolean {
        replace(NjiaKit.openLink(graph, link, facts) ?: return false)
        return true
    }

    /** A fresh flow on the products tab, after the last one finished by backing out of its root. */
    fun restart() {
        replace(NjiaKit.start(graph))
    }

    private fun replace(next: UseSmileIDSampleEngine) {
        engine.removeListener(save)
        engine = next
        watch(next)
    }

    private fun watch(engine: UseSmileIDSampleEngine) {
        engine.addListener(save)
        saved[STATE] = UseSmileIDSampleNjiaCodec.encodeState(engine.state)
    }

    /** A saved state that no longer fits the graph, after an update, starts afresh rather than crashing. */
    private fun restoredEngine(): UseSmileIDSampleEngine? =
        saved.get<String>(STATE)?.let { json -> runCatching { NjiaKit.restore(graph, UseSmileIDSampleNjiaCodec.decodeState(json)) }.getOrNull() }

    private companion object {
        const val STATE = "useSmileIDSampleNjiaState"
    }
}

/** Provided once by the shell, so a step reaches the engine for what its own navigator can't do. */
internal val LocalUseSmileIDSampleEngine = staticCompositionLocalOf<UseSmileIDSampleEngine> {
    error("No UseSmileIDSampleEngine provided")
}

/** The wizard's step kinds, which a run's product is read through. */
private val RUN_STEPS = setOf(
    UseSmileIDSampleStep.ConsentDetailsForm,
    UseSmileIDSampleStep.AuthUserId,
    UseSmileIDSampleStep.IdDetailsForm,
    UseSmileIDSampleStep.SdkFlow,
    UseSmileIDSampleStep.SdkFlowFullScreen,
)

/** The entry a run started at: the nearest wizard entry at or below [entry] that carries the product. */
internal fun UseSmileIDSampleEngine.runStart(entry: NjiaEntry): NjiaEntry? {
    val entries = state.entries
    val at = entries.indexOfFirst { it.id == entry.id }.takeIf { it >= 0 } ?: return null
    return entries.subList(0, at + 1).lastOrNull { it.arg != null && stepOf(it).kind in RUN_STEPS }
}

/** The product the run [entry] belongs to, read from the run's first entry. */
internal fun UseSmileIDSampleEngine.runProductId(entry: NjiaEntry): String? = runStart(entry)?.arg

/** Starts a run of [product] from [from], in place of [replace] if given: sets the run's facts, clears the rest, then goes to its first step carrying the product. */
internal fun UseSmileIDSampleEngine.startRun(
    from: NjiaEntry,
    product: UseSmileIDSampleProduct,
    run: UseSmileIDSampleRunEntry,
    replace: Long? = null,
) {
    send(NjiaIntent.Facts(set = run.facts.toList(), clear = (UseSmileIDSampleFact.entries - run.facts).toList()))
    navigator(from).go(run.step, arg = product.id, replace = replace)
}

/** Leaves the run [entry] belongs to by going to [step] in its place, with [arg]. */
internal fun UseSmileIDSampleEngine.leaveRun(entry: NjiaEntry, step: String, arg: String? = null) {
    val start = runStart(entry) ?: entry
    navigator(entry).go(step, arg = arg, replace = start.id)
}

/** Goes to [step] carrying [arg]: every step's id is its kind's wire name, which the graph test pins. */
internal fun NjiaNavigator.go(step: UseSmileIDSampleStep, arg: String? = null) = go(step.wireName, arg)

/** Back to the products tab's root, which leaves a run however deep it went. */
internal fun UseSmileIDSampleEngine.leaveToProducts() {
    select(UseSmileIDSampleStep.Products.wireName)
}
