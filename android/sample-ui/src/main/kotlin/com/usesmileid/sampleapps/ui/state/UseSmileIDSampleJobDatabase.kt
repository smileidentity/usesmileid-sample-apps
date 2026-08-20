package com.usesmileid.sampleapps.ui.state

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

    /** Newest first, which is the order the list and its date groups both read in. */
    @Query("SELECT * FROM jobs ORDER BY createdAtMillis DESC")
    fun all(): Flow<List<UseSmileIDSampleJobEntity>>

    @Query("SELECT * FROM jobs WHERE id = :id")
    suspend fun find(id: String): UseSmileIDSampleJobEntity?

    /** IGNORE, not REPLACE: a repeated delivery of the same job id must not overwrite the row it already wrote. */
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(jobs: List<UseSmileIDSampleJobEntity>)

    /** REPLACE, for the one caller that means it: a status refresh rewrites the row it just read. */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(job: UseSmileIDSampleJobEntity)

    @Query("DELETE FROM jobs WHERE id IN (:ids)")
    suspend fun delete(ids: Set<String>)

    @Query("SELECT COUNT(*) FROM jobs")
    suspend fun count(): Int
}

@Database(entities = [UseSmileIDSampleJobEntity::class], version = 1, exportSchema = true)
abstract class UseSmileIDSampleJobDatabase : RoomDatabase() {

    abstract fun jobs(): UseSmileIDSampleJobDao

    companion object {
        /**
         * No destructive fallback, deliberately. Version 1 is the first schema anyone will have, so
         * there is nothing in the wild to migrate from yet — and once this ships, a partner's rows are
         * their own submitted verifications. Losing them because a column moved is not something a
         * reference integration should demonstrate.
         *
         * `exportSchema` writes `schemas/…/1.json`, which is committed: it is what a future
         * `Migration` is validated against. The next schema change adds a migration here and bumps the
         * version; without a fallback, forgetting one fails loudly at open time instead of silently
         * emptying the list.
         */
        fun open(context: Context): UseSmileIDSampleJobDatabase =
            Room.databaseBuilder(
                context.applicationContext,
                UseSmileIDSampleJobDatabase::class.java,
                "usesmileid_sample_jobs",
            ).build()
    }
}
