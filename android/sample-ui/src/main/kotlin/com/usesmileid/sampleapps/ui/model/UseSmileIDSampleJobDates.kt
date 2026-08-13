package com.usesmileid.sampleapps.ui.model

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** A day of jobs under one header, which is the shape the verifications list renders. */
data class UseSmileIDSampleJobDay(val relative: String, val absolute: String, val jobs: List<UseSmileIDSampleJob>)

/** Groups jobs by calendar day, newest first. `Calendar` rather than `java.time`, because minSdk is 24 and there is no desugaring. */
fun List<UseSmileIDSampleJob>.groupByDay(
    nowMillis: Long,
    locale: Locale = Locale.getDefault(),
): List<UseSmileIDSampleJobDay> {
    val dayFormat = SimpleDateFormat("EEE, dd MMM yyyy", locale)
    val today = nowMillis.startOfDay()
    return sortedByDescending { it.createdAtMillis }
        .groupBy { it.createdAtMillis.startOfDay() }
        .map { (day, jobs) ->
            UseSmileIDSampleJobDay(
                relative = when (day) {
                    today -> "TODAY"
                    today - MILLIS_PER_DAY -> "YESTERDAY"
                    else -> dayFormat.format(Date(day)).uppercase(locale)
                },
                absolute = dayFormat.format(Date(day)).uppercase(locale),
                jobs = jobs,
            )
        }
}

/** m:ss is the countdown's format; the list shows a wall-clock time instead. */
fun UseSmileIDSampleJob.timeLabel(locale: Locale = Locale.getDefault()): String =
    SimpleDateFormat("HH:mm:ss", locale).format(Date(createdAtMillis))

private fun Long.startOfDay(): Long = Calendar.getInstance().apply {
    timeInMillis = this@startOfDay
    set(Calendar.HOUR_OF_DAY, 0)
    set(Calendar.MINUTE, 0)
    set(Calendar.SECOND, 0)
    set(Calendar.MILLISECOND, 0)
}.timeInMillis

private const val MILLIS_PER_DAY = 24L * 60L * 60L * 1000L
