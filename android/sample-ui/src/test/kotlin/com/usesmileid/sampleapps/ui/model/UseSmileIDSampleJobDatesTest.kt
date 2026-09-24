package com.usesmileid.sampleapps.ui.model

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Test

/** The date helpers the verifications list memoizes on. The module runs its tests in UTC and en_US. */
class UseSmileIDSampleJobDatesTest {

    @Test
    fun `flooring to the start of the day is idempotent`() {
        val once = startOfDayMillis(FIXED_NOW)
        assertEquals(once, startOfDayMillis(once))
    }

    @Test
    fun `every instant in a day floors to the same midnight`() {
        assertEquals(startOfDayMillis(FIXED_NOW), startOfDayMillis(FIXED_NOW + MILLIS_PER_HOUR))
    }

    @Test
    fun `createdAt is ISO-8601 in UTC`() {
        assertEquals("1970-01-01T00:00:00.000Z", job("job-1", createdAtMillis = 0L).createdAtLabel())
    }

    @Test
    fun `time labels match per-job formatting`() {
        val jobs = listOf(
            job("job-1", createdAtMillis = 0L),
            job("job-2", createdAtMillis = MILLIS_PER_HOUR + 2 * MILLIS_PER_MINUTE + 3_000L),
        )
        assertEquals(mapOf("job-1" to "00:00:00", "job-2" to "01:02:03"), jobs.timeLabels(Locale.US))
    }

    @Test
    fun `today and yesterday are named, older days carry no relative word`() {
        val today = startOfDayMillis(FIXED_NOW)
        val jobs = listOf(
            job("today", createdAtMillis = today),
            job("yesterday", createdAtMillis = today - MILLIS_PER_DAY),
            job("older", createdAtMillis = today - 2 * MILLIS_PER_DAY),
        )
        assertEquals(
            listOf("TODAY", "YESTERDAY", ""),
            jobs.groupByDay(today, Locale.US).map { it.relative },
        )
    }

    private fun job(id: String, createdAtMillis: Long) = UseSmileIDSampleJob(
        id = id,
        userId = "user-$id",
        product = UseSmileIDSampleProduct.SmartSelfieEnrollment,
        status = UseSmileIDSampleStatus.Clear,
        createdAtMillis = createdAtMillis,
        message = "",
        httpStatus = 200,
    )

    @Test
    fun `names the day before a 23-hour day as yesterday`() {
        val saved = TimeZone.getDefault()
        // The suite pins UTC, which has no clock change; the zone moves for this test only.
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/London"))
        try {
            fun at(day: Int, hour: Int) = Calendar.getInstance().apply {
                clear()
                set(2026, Calendar.MARCH, day, hour, 0)
            }.timeInMillis
            assertEquals(23L * 3_600_000L, at(30, 0) - at(29, 0))
            val days = listOf(job("dst", createdAtMillis = at(29, 12))).groupByDay(nowMillis = at(30, 12), locale = Locale.US)
            assertEquals("YESTERDAY", days.single().relative)
        } finally {
            TimeZone.setDefault(saved)
        }
    }

    private companion object {
        /** 2026-07-16T11:50:12Z, the instant the goldens are dated from. */
        const val FIXED_NOW = 1_784_202_612_000L
        const val MILLIS_PER_MINUTE = 60_000L
        const val MILLIS_PER_HOUR = 60 * MILLIS_PER_MINUTE
        const val MILLIS_PER_DAY = 24 * MILLIS_PER_HOUR
    }
}
