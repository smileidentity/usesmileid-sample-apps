package com.usesmileid.sampleapps.android.navigation

import android.content.Context
import com.usesmileid.njia.NjiaCodec
import com.usesmileid.njia.NjiaGraph
import com.usesmileid.njia.NjiaWire
import com.usesmileid.njia.decodeGraph

/** What a step of `spec/njia-graph.json` shows: its `kind`, named as the graph names it. */
internal enum class UseSmileIDSampleStep(val wireName: String) {
    Products("products"),
    Verifications("verifications"),
    Settings("settings"),
    Licenses("licenses"),
    CaptureMode("captureMode"),
    Submission("submission"),
    Appearance("appearance"),
    Language("language"),
    ScenarioDrawer("scenarioDrawer"),
    VerificationDetails("verificationDetails"),
    ProfileSwitch("profileSwitch"),
    Profiles("profiles"),
    NewProfile("newProfile"),
    ProfileConfig("profileConfig"),
    ScanToken("scanToken"),
    CountryPicker("countryPicker"),
    IdTypePicker("idTypePicker"),
    DocumentPicker("documentPicker"),
    CaptureAs("captureAs"),
    GenericDocument("genericDocument"),
    ConsentDetailsForm("consentDetailsForm"),
    AuthUserId("authUserId"),
    IdDetailsForm("idDetailsForm"),
    SdkFlow("sdkFlow"),
    SdkFlowFullScreen("sdkFlowFullScreen"),
}

/** What a run's product, token and launch say about it: the facts the graph's `skipWhen` reads. */
internal enum class UseSmileIDSampleFact(val wireName: String) {
    /** SmartSelfie Authentication, which asks for the user ID to authenticate. */
    NeedsUserId("needsUserId"),

    /** A product that needs ID details the token doesn't already bind. */
    NeedsIdDetails("needsIdDetails"),

    /** The run was launched full screen, over the tab bar. */
    FullScreenRun("fullScreenRun"),
}

/** Reads the graph with the app's own kinds and facts, so one the app doesn't know fails to decode. */
internal val UseSmileIDSampleNjiaCodec: NjiaCodec<UseSmileIDSampleStep, UseSmileIDSampleFact> =
    NjiaCodec(NjiaWire.enum { it.wireName }, NjiaWire.enum { it.wireName })

/** The graph the build bundles from `spec/njia-graph.json`, under the same name. */
internal const val USE_SMILE_ID_SAMPLE_NJIA_GRAPH = "njia-graph.json"

/** The four apps' one navigation graph, as this build bundles it. */
internal fun Context.useSmileIDSampleNjiaGraph(): NjiaGraph<UseSmileIDSampleStep, UseSmileIDSampleFact> =
    UseSmileIDSampleNjiaCodec.decodeGraph(assets.open(USE_SMILE_ID_SAMPLE_NJIA_GRAPH).bufferedReader().use { it.readText() })
