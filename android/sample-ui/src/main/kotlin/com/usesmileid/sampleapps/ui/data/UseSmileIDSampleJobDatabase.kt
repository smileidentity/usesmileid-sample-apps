package com.usesmileid.sampleapps.ui.data

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import kotlinx.coroutines.flow.Flow

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
    suspend fun updateStatus(id: String, statusId: String, message: String, httpStatus: String): Int

    @Query("DELETE FROM jobs WHERE id IN (:ids)")
    suspend fun delete(ids: Set<String>)

    @Query("SELECT COUNT(*) FROM jobs")
    suspend fun count(): Int
}

@Database(entities = [UseSmileIDSampleJobEntity::class], version = 1, exportSchema = true)
abstract class UseSmileIDSampleJobDatabase : RoomDatabase() {

    abstract fun jobs(): UseSmileIDSampleJobDao

    companion object {
        /** No destructive fallback: a forgotten migration must fail at open time, not empty a partner's rows. */
        fun open(context: Context): UseSmileIDSampleJobDatabase =
            Room.databaseBuilder(
                context.applicationContext,
                UseSmileIDSampleJobDatabase::class.java,
                "usesmileid_sample_jobs",
            ).build()
    }
}
