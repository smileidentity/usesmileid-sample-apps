package com.usesmileid.sampleapps.ui.model

/** The products grid in design order, asserted against `spec/scenarios.json` by a unit test. `capture = false` is Enhanced KYC, the one journey without `capture()`. */
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
    EnhancedDocumentVerification("enhancedDocumentVerification", "Enhanced Document Verification", UseSmileIDSampleProductSection.Verifications, needsIdDetails = true),
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
