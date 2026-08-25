package com.usesmileid.sampleapps.ui.model

import com.usesmileid.sampleapps.ui.UseSmileIDSampleMarks

/**
 * The products grid in design order, asserted against `spec/scenarios.json` by a unit test.
 * `capture = false` is Enhanced KYC, the one journey without `capture()`.
 *
 * [label] is the SDK's job-type name in full and is what the verifications row and the result card
 * read; [cardTitle] and [cardFamily] are the card's two runs, shortened to fit its text column.
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

enum class UseSmileIDSampleProductSection(val label: String) {
    Authentication("Biometric Authentication"),
    Verifications("Verifications"),
}
