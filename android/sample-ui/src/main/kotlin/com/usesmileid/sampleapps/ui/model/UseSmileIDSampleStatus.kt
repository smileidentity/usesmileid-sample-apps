package com.usesmileid.sampleapps.ui.model

/** The five job statuses, Title case as the design sets them. Error has no design frame: the API returns it as its own final state. */
enum class UseSmileIDSampleStatus {
    Clear,
    Attention,
    Blocked,
    Error,
    Processing,
}
