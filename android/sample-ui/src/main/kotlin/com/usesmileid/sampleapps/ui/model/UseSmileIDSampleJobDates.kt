package com.usesmileid.sampleapps.ui.model

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

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

/** Midnight of the day [nowMillis] falls in, so a consumer can read the clock coarsely. Idempotent. */
fun startOfDayMillis(nowMillis: Long): Long = nowMillis.startOfDay()

/** m:ss is the countdown's format; the list shows a wall-clock time instead. One formatter for the whole list. */
fun List<UseSmileIDSampleJob>.timeLabels(locale: Locale = Locale.getDefault()): Map<String, String> {
    val format = SimpleDateFormat("HH:mm:ss", locale)
    return associate { it.id to format.format(Date(it.createdAtMillis)) }
}

/** ISO-8601 in UTC, matching the design's row: a machine-readable value, not a display date. */
fun UseSmileIDSampleJob.createdAtLabel(): String = utcIsoFormat.format(Date(createdAtMillis))

// Main-thread only, like every composable read.
private val utcIsoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
    timeZone = TimeZone.getTimeZone("UTC")
}

private fun Long.startOfDay(): Long = Calendar.getInstance().apply {
    timeInMillis = this@startOfDay
    set(Calendar.HOUR_OF_DAY, 0)
    set(Calendar.MINUTE, 0)
    set(Calendar.SECOND, 0)
    set(Calendar.MILLISECOND, 0)
}.timeInMillis

private const val MILLIS_PER_DAY = 24L * 60L * 60L * 1000L
