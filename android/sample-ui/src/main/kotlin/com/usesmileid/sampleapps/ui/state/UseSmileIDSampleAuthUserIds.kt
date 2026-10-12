package com.usesmileid.sampleapps.ui.state

import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleJob
import com.usesmileid.sampleapps.ui.model.UseSmileIDSampleStatus

/** This partner's enrolling runs in this environment, not refused or failed, newest first, one per user. */
fun previousAuthUsers(jobs: List<UseSmileIDSampleJob>, partnerId: String?, sandbox: Boolean): List<UseSmileIDSampleJob> = jobs
    .filter { partnerId != null && it.partnerId == partnerId && it.sandbox == sandbox }
    .filter { it.product.enrollsUser && it.status !in REJECTED && it.userId.isNotBlank() }
    .sortedByDescending { it.createdAtMillis }
    .distinctBy { it.userId }

private val REJECTED = setOf(UseSmileIDSampleStatus.Blocked, UseSmileIDSampleStatus.Error)
