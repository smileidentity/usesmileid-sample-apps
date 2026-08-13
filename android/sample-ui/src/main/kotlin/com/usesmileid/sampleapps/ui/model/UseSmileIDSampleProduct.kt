package com.usesmileid.sampleapps.ui.model

/**
 * The products grid, in the design's order. Mirrors `spec/scenarios.json` → products, which is the
 * contract all four apps implement; a unit test asserts this list against it.
 *
 * `capture = false` is not a gap: Enhanced KYC composes the SDK flow without `capture()`, which is
 * the one journey proving the flow works without it.
 */
enum class UseSmileIDSampleProduct(
    val id: String,
    val label: String,
    val section: UseSmileIDSampleProductSection,
    val capture: Boolean = true,
    val needsIdDetails: Boolean = false,
) {
    SmartSelfieEnrollment("smartSelfieEnrollment", "SmartSelfie Enrollment", UseSmileIDSampleProductSection.Authentication),
    SmartSelfieAuth("smartSelfieAuth", "SmartSelfie Authentication", UseSmileIDSampleProductSection.Authentication),
    DocumentVerification("documentVerification", "Document Verification", UseSmileIDSampleProductSection.Verifications, needsIdDetails = true),
    EnhancedDocumentVerification("enhancedDocumentVerification", "Enhanced Doc Verification", UseSmileIDSampleProductSection.Verifications, needsIdDetails = true),
    BiometricKyc("biometricKyc", "Biometric KYC", UseSmileIDSampleProductSection.Verifications, needsIdDetails = true),
    EnhancedKyc("enhancedKyc", "Enhanced KYC", UseSmileIDSampleProductSection.Verifications, capture = false, needsIdDetails = true),
    ;

    companion object {
        fun of(section: UseSmileIDSampleProductSection) = entries.filter { it.section == section }
    }
}

enum class UseSmileIDSampleProductSection(val label: String) {
    Authentication("Authentication"),
    Verifications("Verifications"),
}
