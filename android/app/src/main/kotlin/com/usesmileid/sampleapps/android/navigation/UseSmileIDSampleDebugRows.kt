package com.usesmileid.sampleapps.android.navigation

/** Who draws each part of the Settings DEBUG section below Scenarios. */
internal enum class UseSmileIDSampleDebugRowGroup {
    /** The extension's leading rows, such as a device identity. */
    ExtensionLeading,

    /** The shell's own rows: Network logs. */
    Shell,

    /** The extension's other rows, such as Show diagnostics. */
    Extension,
}

/** The order the DEBUG section draws its groups in, which a source build's rows rely on. */
internal val useSmileIDSampleDebugRowOrder: List<UseSmileIDSampleDebugRowGroup> = UseSmileIDSampleDebugRowGroup.entries
