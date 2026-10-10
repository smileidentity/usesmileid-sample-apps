package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus

/** The user IDs SmartSelfie Authentication can run as: this partner's jobs in this environment that enrol a user and were not refused or failed, newest first, once each. */
fun previousAuthUserIds(jobs: List<UseSmileIDSampleJob>, partnerId: String?, sandbox: Boolean): List<String> = jobs
    .filter { partnerId != null && it.partnerId == partnerId && it.sandbox == sandbox }
    .filter { it.product.enrollsUser && it.status !in REJECTED && it.userId.isNotBlank() }
    .sortedByDescending { it.createdAtMillis }
    .map { it.userId }
    .distinct()

private val REJECTED = setOf(UseSmileIDSampleStatus.Blocked, UseSmileIDSampleStatus.Error)
