package com.usesmileid.sampleapps.ui.model

/**
 * The flow scenarios the drawer offers. Mirrors `spec/scenarios.json`, which all four apps
 * implement, and a unit test asserts this list against it.
 */
enum class UseSmileIDSampleScenario(val id: String, val label: String, val description: String) {
    Normal("normal", "Normal", "Happy path with valid sandbox credentials."),
    ExpiredToken("expiredToken", "Expired token", "Token is valid but expired, so the SDK must refresh before it can submit."),
    BadRefresh("badRefresh", "Refresh fails", "Refresh returns an unusable token, so the failure path must surface."),
    NoCallback("noCallback", "No result callback", "Host provides no result callback; the SDK must not crash or hang."),
    ThrowingCallback("throwingCallback", "Throwing callback", "Host callback throws; it must not corrupt SDK state."),
    OfflineRetry("offlineRetry", "Offline then retry", "Submission starts with no connectivity, then it returns."),
}

/** Theme scenarios apply on top of any flow scenario, through the SDK's public theme override. */
enum class UseSmileIDSampleThemeScenario(val id: String, val label: String, val description: String) {
    BrandDefault("brandDefault", "Brand default", "Ship state: Smile ID branding, light or dark per the Settings switch."),
    ClashingHost("clashingHost", "Clashing host", "A deliberately distant host theme, to expose host-versus-SDK collisions."),
    PartnerOverride("partnerOverride", "Partner override", "A plausible partner palette through the same public override."),
}
