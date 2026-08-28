package com.usesmileid.sampleapps.ui.data

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.flow.Flow

/** The verification rows: inserts IGNORE so a repeated delivery cannot overwrite one; only a status refresh UPDATEs. */
@Dao
interface UseSmileIDSampleJobDao {

    /** Newest first, which is how the list and its date groups read. */
    @Query("SELECT * FROM jobs ORDER BY createdAtMillis DESC")
    fun all(): Flow<List<UseSmileIDSampleJobEntity>>

    @Query("SELECT * FROM jobs WHERE id = :id")
    suspend fun find(id: String): UseSmileIDSampleJobEntity?

    @Query("SELECT * FROM jobs WHERE id IN (:ids)")
    suspend fun findAll(ids: Set<String>): List<UseSmileIDSampleJobEntity>

    /** IGNORE, not REPLACE: a repeated delivery must not overwrite the row it already wrote. */
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(jobs: List<UseSmileIDSampleJobEntity>)

    /** One atomic write for the one caller that overwrites: a status refresh. Returns affected rows, so a deleted row reports 0. */
    @Query("UPDATE jobs SET statusId = :statusId, message = :message, httpStatus = :httpStatus WHERE id = :id")
    suspend fun updateStatus(id: String, statusId: String, message: String, httpStatus: Int): Int

    @Query("DELETE FROM jobs WHERE id IN (:ids)")
    suspend fun delete(ids: Set<String>)

    @Query("SELECT COUNT(*) FROM jobs")
    suspend fun count(): Int
}

/** The verification store's one database; its schema is exported and committed, so migrations are checkable. */
@Database(entities = [UseSmileIDSampleJobEntity::class], version = 3, exportSchema = true)
abstract class UseSmileIDSampleJobDatabase : RoomDatabase() {

    abstract fun jobs(): UseSmileIDSampleJobDao

    companion object {
        /** No destructive fallback: a forgotten migration must fail at open time, not empty a partner's rows. */
        fun open(context: Context): UseSmileIDSampleJobDatabase =
            Room.databaseBuilder(
                context.applicationContext,
                UseSmileIDSampleJobDatabase::class.java,
                "usesmileid_sample_jobs",
            ).addMigrations(MIGRATION_1_2, MIGRATION_2_3).build()

        /** v1 stored display text ("200 OK"); v2 stores the raw code. SQLite CAST reads the leading digits. */
        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                // Column type changes need a rebuild; the CREATE is the generated 2.json createSql verbatim.
                db.execSQL(
                    "CREATE TABLE IF NOT EXISTS `jobs_v2` (`id` TEXT NOT NULL, `userId` TEXT NOT NULL, " +
                        "`productId` TEXT NOT NULL, `statusId` TEXT NOT NULL, `createdAtMillis` INTEGER NOT NULL, " +
                        "`message` TEXT NOT NULL, `httpStatus` INTEGER, `sandbox` INTEGER NOT NULL, " +
                        "`sessionId` TEXT, `boundUserDetails` INTEGER NOT NULL DEFAULT 0, " +
                        "`boundIdDetails` INTEGER NOT NULL DEFAULT 0, `boundConsent` INTEGER NOT NULL DEFAULT 0, " +
                        "PRIMARY KEY(`id`))",
                )
                db.execSQL(
                    "INSERT INTO `jobs_v2` SELECT `id`, `userId`, `productId`, `statusId`, `createdAtMillis`, " +
                        "`message`, CASE WHEN trim(`httpStatus`) = '' THEN NULL ELSE CAST(`httpStatus` AS INTEGER) END, " +
                        "`sandbox`, `sessionId`, `boundUserDetails`, `boundIdDetails`, `boundConsent` FROM `jobs`",
                )
                db.execSQL("DROP TABLE `jobs`")
                db.execSQL("ALTER TABLE `jobs_v2` RENAME TO `jobs`")
            }
        }

        /** v3 adds the partner a row was submitted under, which is what a later session's refresh matches on. */
        val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE `jobs` ADD COLUMN `partnerId` TEXT")
            }
        }
    }
}
