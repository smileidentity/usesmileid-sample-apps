package com.usesmileid.sampleapps.ui.data

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.usesmileid.sampleapps.ui.golden.ROBOLECTRIC_SDK
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Room validates the migrated schema when it opens, so an open that succeeds is the migration passing. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [ROBOLECTRIC_SDK])
class UseSmileIDSampleJobMigrationTest {

    @Test
    fun `migrating v1 rows turns display strings into codes and leaves the partner unknown`() = runTest {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val name = "migration-test"
        context.deleteDatabase(name)
        SQLiteDatabase.openOrCreateDatabase(context.getDatabasePath(name).apply { parentFile?.mkdirs() }, null)
            .use { db ->
                db.execSQL(V1_CREATE_JOBS)
                db.execSQL(V1_MASTER_TABLE)
                db.execSQL(V1_IDENTITY_HASH)
                db.execSQL(
                    "INSERT INTO jobs VALUES " +
                        "('job-1','user-1','smartSelfieEnrollment','Clear',1,'Approved','200 OK',1,'s-1',0,0,0)",
                )
                db.execSQL(
                    "INSERT INTO jobs VALUES " +
                        "('job-2','user-2','smartSelfieEnrollment','Processing',2,'Submitted','202 Accepted',1,NULL,0,0,0)",
                )
                // A row that never got an answer stored the empty string, which must read as unknown, not 0.
                db.execSQL(
                    "INSERT INTO jobs VALUES " +
                        "('job-3','user-3','smartSelfieEnrollment','Processing',3,'Submitted','',0,NULL,0,0,0)",
                )
                db.version = 1
            }

        val database = Room.databaseBuilder(context, UseSmileIDSampleJobDatabase::class.java, name)
            .addMigrations(
                UseSmileIDSampleJobDatabase.MIGRATION_1_2,
                UseSmileIDSampleJobDatabase.MIGRATION_2_3,
            )
            .build()
        try {
            val rows = database.jobs().all().first().associateBy { it.id }
            assertEquals(200, rows.getValue("job-1").httpStatus)
            assertEquals(202, rows.getValue("job-2").httpStatus)
            assertNull(rows.getValue("job-3").httpStatus)
            // The rest of the row has to survive the table rebuild, not just the changed column.
            assertEquals("s-1", rows.getValue("job-1").sessionId)
            assertEquals(false, rows.getValue("job-3").sandbox)
            assertNull(rows.getValue("job-1").partnerId)
        } finally {
            database.close()
        }
    }

    private companion object {
        /** `createSql` from the committed `1.json`, with `${'$'}{TABLE_NAME}` resolved. */
        const val V1_CREATE_JOBS = "CREATE TABLE IF NOT EXISTS `jobs` (`id` TEXT NOT NULL, `userId` TEXT NOT NULL, " +
            "`productId` TEXT NOT NULL, `statusId` TEXT NOT NULL, `createdAtMillis` INTEGER NOT NULL, " +
            "`message` TEXT NOT NULL, `httpStatus` TEXT NOT NULL, `sandbox` INTEGER NOT NULL, `sessionId` TEXT, " +
            "`boundUserDetails` INTEGER NOT NULL DEFAULT 0, `boundIdDetails` INTEGER NOT NULL DEFAULT 0, " +
            "`boundConsent` INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(`id`))"

        /** Room reads its own identity row on open, so a hand-built v1 has to carry v1's hash. */
        const val V1_MASTER_TABLE = "CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY," +
            "identity_hash TEXT)"
        const val V1_IDENTITY_HASH = "INSERT OR REPLACE INTO room_master_table (id,identity_hash) " +
            "VALUES(42, 'b4a977e274fc5e9fd2be338dd1952c0d')"
    }
}
