package com.usesmileid.sampleapps.ui

import android.content.res.Resources
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalResources
import com.usesmileid.sampleapps.ui.data.UseSmileIDSampleStatusRefresh
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleEnvironment
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJobFilter
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProduct
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleProductSection
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleSimulatedSpan
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleAspectRatio
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAs
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleCaptureAsWording
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleDocumentOrientation
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleIdNumberHint
import com.usesmileid.sampleapps.ui.state.UseSmileIDSampleTokenRejection

/** The product's name in the app's language. */
@Composable
fun UseSmileIDSampleProduct.localizedTitle(): String = when (this) {
    UseSmileIDSampleProduct.SmartSelfieEnrollment -> UseSmileIDSampleStrings.productSmartSelfieEnrollment
    UseSmileIDSampleProduct.SmartSelfieAuth -> UseSmileIDSampleStrings.productSmartSelfieAuthentication
    UseSmileIDSampleProduct.DocumentVerification -> UseSmileIDSampleStrings.productDocumentVerification
    UseSmileIDSampleProduct.EnhancedDocumentVerification -> UseSmileIDSampleStrings.productEnhancedDocumentVerification
    UseSmileIDSampleProduct.ResidencyDocumentVerification -> UseSmileIDSampleStrings.productResidencyDocumentVerification
    UseSmileIDSampleProduct.BiometricKyc -> UseSmileIDSampleStrings.productBiometricKyc
    UseSmileIDSampleProduct.EnhancedKyc -> UseSmileIDSampleStrings.productEnhancedKyc
}

/** The card's first line in the app's language. */
@Composable
fun UseSmileIDSampleProduct.localizedCardTitle(): String = when (this) {
    UseSmileIDSampleProduct.SmartSelfieEnrollment -> UseSmileIDSampleStrings.productCardRegistration
    UseSmileIDSampleProduct.SmartSelfieAuth -> UseSmileIDSampleStrings.productCardAuth
    UseSmileIDSampleProduct.DocumentVerification -> UseSmileIDSampleStrings.productCardDocument
    UseSmileIDSampleProduct.EnhancedDocumentVerification -> UseSmileIDSampleStrings.productCardEnhancedDoc
    UseSmileIDSampleProduct.ResidencyDocumentVerification -> UseSmileIDSampleStrings.productCardResidencyDoc
    UseSmileIDSampleProduct.BiometricKyc -> UseSmileIDSampleStrings.productCardBiometric
    UseSmileIDSampleProduct.EnhancedKyc -> UseSmileIDSampleStrings.productCardEnhanced
}

/** The card's second line; the SmartSelfie mark is never translated. */
@Composable
fun UseSmileIDSampleProduct.localizedCardFamily(): String = when (cardFamily) {
    UseSmileIDSampleMarks.SMART_SELFIE -> cardFamily
    "KYC" -> UseSmileIDSampleStrings.productFamilyKyc
    else -> UseSmileIDSampleStrings.productFamilyVerification
}

@Composable
fun UseSmileIDSampleProductSection.label(): String = when (this) {
    UseSmileIDSampleProductSection.Authentication -> UseSmileIDSampleStrings.productsSectionAuthentication
    UseSmileIDSampleProductSection.Verifications -> UseSmileIDSampleStrings.productsSectionOnboarding
}

@Composable
fun UseSmileIDSampleStatus.label(): String = when (this) {
    UseSmileIDSampleStatus.Clear -> UseSmileIDSampleStrings.statusClear
    UseSmileIDSampleStatus.Attention -> UseSmileIDSampleStrings.statusAttention
    UseSmileIDSampleStatus.Blocked -> UseSmileIDSampleStrings.statusBlocked
    UseSmileIDSampleStatus.Error -> UseSmileIDSampleStrings.statusError
    UseSmileIDSampleStatus.Processing -> UseSmileIDSampleStrings.statusProcessing
}

@Composable
fun UseSmileIDSampleJobFilter.label(): String = status?.label() ?: UseSmileIDSampleStrings.verificationsFilterAll

@Composable
fun UseSmileIDSampleEnvironment.label(): String = when (this) {
    UseSmileIDSampleEnvironment.Sandbox -> UseSmileIDSampleStrings.scanEnvironmentSandbox
    UseSmileIDSampleEnvironment.Production -> UseSmileIDSampleStrings.scanEnvironmentProduction
}

/** The span's chip label; only the ended span is translated. */
@Composable
fun UseSmileIDSampleSimulatedSpan.label(): String = if (ended) UseSmileIDSampleStrings.scanSpanExpired else shortLabel

/** One line per outcome, read outside composition. */
fun UseSmileIDSampleStatusRefresh.message(resources: Resources): String = when (this) {
    is UseSmileIDSampleStatusRefresh.Updated ->
        resources.getString(R.string.sample_status_refresh_result, resources.getString(status.labelRes), message)
    UseSmileIDSampleStatusRefresh.StillProcessing -> resources.getString(R.string.sample_status_refresh_processing)
    UseSmileIDSampleStatusRefresh.NotRecorded -> resources.getString(R.string.sample_status_refresh_failed, NOT_RECORDED_DETAIL)
    UseSmileIDSampleStatusRefresh.NoSession -> resources.getString(R.string.sample_status_refresh_no_session)
    UseSmileIDSampleStatusRefresh.NoServerJob -> resources.getString(R.string.sample_status_refresh_not_token_job)
    UseSmileIDSampleStatusRefresh.PartnerMismatch -> resources.getString(R.string.sample_status_refresh_other_partner)
    is UseSmileIDSampleStatusRefresh.Failed -> resources.getString(R.string.sample_status_refresh_failed, reason.message(resources))
}

/** The failure in words; a server's own detail is shown as it came. */
fun UseSmileIDSampleStatusRefresh.Reason.message(resources: Resources): String = when (this) {
    UseSmileIDSampleStatusRefresh.Reason.NotStored -> resources.getString(R.string.sample_job_error_not_stored)
    UseSmileIDSampleStatusRefresh.Reason.Unreachable -> resources.getString(R.string.sample_job_error_unreachable)
    is UseSmileIDSampleStatusRefresh.Reason.Unexpected -> resources.getString(R.string.sample_job_error_unexpected, type)
    is UseSmileIDSampleStatusRefresh.Reason.Detail -> text
}

/** The status's string, for callers outside composition. */
val UseSmileIDSampleStatus.labelRes: Int
    get() = when (this) {
        UseSmileIDSampleStatus.Clear -> R.string.sample_status_clear
        UseSmileIDSampleStatus.Attention -> R.string.sample_status_attention
        UseSmileIDSampleStatus.Blocked -> R.string.sample_status_blocked
        UseSmileIDSampleStatus.Error -> R.string.sample_status_error
        UseSmileIDSampleStatus.Processing -> R.string.sample_status_processing
    }

/** The rejection in words. */
fun UseSmileIDSampleTokenRejection.message(resources: Resources): String = when (this) {
    UseSmileIDSampleTokenRejection.Segments -> resources.getString(R.string.sample_token_error_segments)
    UseSmileIDSampleTokenRejection.PayloadEncoding -> resources.getString(R.string.sample_token_error_payload_encoding)
    UseSmileIDSampleTokenRejection.PayloadJson -> resources.getString(R.string.sample_token_error_payload_json)
    UseSmileIDSampleTokenRejection.IssuedAt -> resources.getString(R.string.sample_token_error_iat)
    UseSmileIDSampleTokenRejection.Expiry -> resources.getString(R.string.sample_token_error_exp)
    UseSmileIDSampleTokenRejection.ExpiryOrder -> resources.getString(R.string.sample_token_error_exp_order)
    UseSmileIDSampleTokenRejection.ApiUrlMissing -> resources.getString(R.string.sample_token_error_api_url_missing)
    is UseSmileIDSampleTokenRejection.ApiUrlUnknown -> resources.getString(R.string.sample_token_error_api_url_unknown, host)
    UseSmileIDSampleTokenRejection.ApiUrlInvalid -> resources.getString(R.string.sample_token_error_api_url_invalid)
}

/** The ID-number field's placeholder in the app's language. */
@Composable
fun UseSmileIDSampleIdNumberHint.Placeholder.text(): String = when (this) {
    UseSmileIDSampleIdNumberHint.Placeholder.ChooseType -> UseSmileIDSampleStrings.kycChooseIdTypeFirst
    is UseSmileIDSampleIdNumberHint.Placeholder.Enter -> UseSmileIDSampleStrings.kycIdNumberPlaceholder(idType)
    is UseSmileIDSampleIdNumberHint.Placeholder.Example -> UseSmileIDSampleStrings.kycIdNumberExample(example)
}

/** The line under a number that does not fit. */
@Composable
fun UseSmileIDSampleIdNumberHint.Mismatch.text(): String =
    example?.let { UseSmileIDSampleStrings.kycIdNumberInvalidExample(idType, it) }
        ?: UseSmileIDSampleStrings.kycIdNumberInvalid(idType)

/** A capture-as type's row name in the app's language. */
@Composable
fun UseSmileIDSampleCaptureAs.label(): String = when (this) {
    UseSmileIDSampleCaptureAs.GenericDocument -> UseSmileIDSampleStrings.captureAsGenericDocument
    UseSmileIDSampleCaptureAs.GreenBook -> UseSmileIDSampleStrings.captureAsGreenBook
    UseSmileIDSampleCaptureAs.Passport -> UseSmileIDSampleStrings.captureAsPassport
}

@Composable
fun UseSmileIDSampleDocumentOrientation.label(): String = when (this) {
    UseSmileIDSampleDocumentOrientation.Landscape -> UseSmileIDSampleStrings.genericDocumentLandscape
    UseSmileIDSampleDocumentOrientation.Portrait -> UseSmileIDSampleStrings.genericDocumentPortrait
}

/** The ratio's row; the number is written the same in every language. */
@Composable
fun UseSmileIDSampleAspectRatio.label(): String = when (this) {
    UseSmileIDSampleAspectRatio.Off -> UseSmileIDSampleStrings.genericDocumentRatioOff
    UseSmileIDSampleAspectRatio.Card -> UseSmileIDSampleStrings.genericDocumentRatioCard
    UseSmileIDSampleAspectRatio.Passport -> UseSmileIDSampleStrings.genericDocumentRatioPassport
    UseSmileIDSampleAspectRatio.Booklet -> UseSmileIDSampleStrings.genericDocumentRatioBooklet
}

/** The capture-as wording in the app's language. */
@Composable
fun rememberUseSmileIDSampleCaptureAsWording(): UseSmileIDSampleCaptureAsWording {
    val resources = LocalResources.current
    return remember(resources) {
        fun text(id: Int, vararg args: Any) = resources.getString(id, *args)
        UseSmileIDSampleCaptureAsWording(
            captureAs = {
                when (it) {
                    UseSmileIDSampleCaptureAs.GenericDocument -> text(R.string.sample_capture_as_generic_document)
                    UseSmileIDSampleCaptureAs.GreenBook -> text(R.string.sample_capture_as_green_book)
                    UseSmileIDSampleCaptureAs.Passport -> text(R.string.sample_capture_as_passport)
                }
            },
            orientation = {
                when (it) {
                    UseSmileIDSampleDocumentOrientation.Landscape -> text(R.string.sample_generic_document_landscape)
                    UseSmileIDSampleDocumentOrientation.Portrait -> text(R.string.sample_generic_document_portrait)
                }
            },
            frontAndBack = text(R.string.sample_capture_as_front_and_back),
            frontOnly = text(R.string.sample_capture_as_front_only),
            matches = { text(R.string.sample_capture_as_matches, it) },
            chosen = { text(R.string.sample_capture_as_chosen, it) },
            genericSummary = { captureAs, orientation, sides ->
                text(R.string.sample_capture_as_generic_summary, captureAs, orientation, sides)
            },
            genericNamedSummary = { name, orientation, sides ->
                text(R.string.sample_capture_as_generic_named_summary, name, orientation, sides)
            },
            matchNamed = { text(R.string.sample_capture_as_match_named, it) },
        )
    }
}

/** What a job the server never recorded reads as: the code it answered with. */
private const val NOT_RECORDED_DETAIL = "HTTP 404"
