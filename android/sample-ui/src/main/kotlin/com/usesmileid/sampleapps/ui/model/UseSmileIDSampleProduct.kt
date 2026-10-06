package com.usesmileid.sampleapps.ui.model

import com.usesmileid.sampleapps.ui.UseSmileIDSampleMarks

/**
 * The products grid in design order, asserted against `spec/scenarios.json` by a unit test.
 * `capture = false` is Enhanced KYC, the one journey without `capture()`.
 *
 * [label], [cardTitle] and [cardFamily] are the English the result card and `spec/screens.json` read; screens translate.
 */
enum class UseSmileIDSampleProduct(
    val id: String,
    val label: String,
    val cardTitle: String,
    val cardFamily: String,
    val section: UseSmileIDSampleProductSection,
    val capture: Boolean = true,
    val needsIdDetails: Boolean = false,
) {
    SmartSelfieEnrollment(
        "smartSelfieEnrollment",
        "SmartSelfie Enrollment",
        "Registration",
        UseSmileIDSampleMarks.SMART_SELFIE,
        UseSmileIDSampleProductSection.Authentication,
    ),
    SmartSelfieAuth(
        "smartSelfieAuth",
        "SmartSelfie Authentication",
        "Auth",
        UseSmileIDSampleMarks.SMART_SELFIE,
        UseSmileIDSampleProductSection.Authentication,
    ),
    DocumentVerification(
        "documentVerification",
        "Document Verification",
        "Document",
        "Verification",
        UseSmileIDSampleProductSection.Verifications,
        needsIdDetails = true,
    ),
    EnhancedDocumentVerification(
        "enhancedDocumentVerification",
        "Enhanced Document Verification",
        "Enhanced Doc.",
        "Verification",
        UseSmileIDSampleProductSection.Verifications,
        needsIdDetails = true,
    ),
    ResidencyDocumentVerification(
        "residencyDocumentVerification",
        "Residency Document Verification",
        "Residency Doc.",
        "Verification",
        UseSmileIDSampleProductSection.Verifications,
        needsIdDetails = true,
    ),
    BiometricKyc(
        "biometricKyc",
        "Biometric KYC",
        "Biometric",
        "KYC",
        UseSmileIDSampleProductSection.Verifications,
        needsIdDetails = true,
    ),
    EnhancedKyc(
        "enhancedKyc",
        "Enhanced KYC",
        "Enhanced",
        "KYC",
        UseSmileIDSampleProductSection.Verifications,
        capture = false,
        needsIdDetails = true,
    ),
    ;

    companion object {
        fun of(section: UseSmileIDSampleProductSection) = entries.filter { it.section == section }
    }
}

/** Constant names outlive their labels: the second section is the Onboarding heading, not the Verifications tab. */
enum class UseSmileIDSampleProductSection {
    Authentication,
    Verifications,
}
