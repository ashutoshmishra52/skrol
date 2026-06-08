package com.ashutoshmishra.scrollless

import android.content.Context
import java.util.Calendar

object AppSwitchTracker {
    private const val PREFS = "scrollless_tracker"
    private const val KEY_INSTALL_MS = "install_ms"
    private const val KEY_SWITCH_COUNT = "switch_count"
    private const val KEY_PERIOD_DATE = "period_date"
    private const val KEY_REELS = "reels_count"
    private const val KEY_SHORTS = "shorts_count"
    private const val KEY_REELS_WATCH_MS = "reels_watch_ms"
    private const val KEY_SHORTS_WATCH_MS = "shorts_watch_ms"

    fun ensureInitialized(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.contains(KEY_INSTALL_MS)) {
            prefs.edit().putLong(KEY_INSTALL_MS, System.currentTimeMillis()).apply()
        }
        resetIfNewPeriod(context)
    }

    fun resetIfNewPeriod(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val periodKey = currentPeriodKey()
        val stored = prefs.getString(KEY_PERIOD_DATE, "") ?: ""

        if (stored.isNotEmpty() && stored != periodKey) {
            archiveAndReset(context, prefs, stored, periodKey)
            return
        }

        if (stored.isEmpty()) {
            prefs.edit().putString(KEY_PERIOD_DATE, periodKey).apply()
        }
    }

    private fun archiveAndReset(
        context: Context,
        prefs: android.content.SharedPreferences,
        oldDateKey: String,
        newDateKey: String,
    ) {
        DailyHistoryStore.archiveDay(
            context = context,
            dateKey = oldDateKey,
            reels = prefs.getInt(KEY_REELS, 0),
            shorts = prefs.getInt(KEY_SHORTS, 0),
            reelsWatchMs = prefs.getLong(KEY_REELS_WATCH_MS, 0L),
            shortsWatchMs = prefs.getLong(KEY_SHORTS_WATCH_MS, 0L),
        )

        val editor = prefs.edit()
            .putString(KEY_PERIOD_DATE, newDateKey)
            .putInt(KEY_SWITCH_COUNT, 0)
            .putInt(KEY_REELS, 0)
            .putInt(KEY_SHORTS, 0)
            .putLong(KEY_REELS_WATCH_MS, 0L)
            .putLong(KEY_SHORTS_WATCH_MS, 0L)

        for (key in prefs.all.keys) {
            if (key.startsWith("hour_reels_") || key.startsWith("hour_shorts_")) {
                editor.remove(key)
            }
        }
        editor.apply()
    }

    private fun currentPeriodKey(): String = DailyHistoryStore.periodKey()

    fun onAppForeground(context: Context, packageName: String) {
        if (packageName.isBlank() || packageName == context.packageName) return
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val count = prefs.getInt(KEY_SWITCH_COUNT, 0) + 1
        prefs.edit().putInt(KEY_SWITCH_COUNT, count).apply()
    }

    fun getSwitchCount(context: Context): Int {
        resetIfNewPeriod(context)
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(KEY_SWITCH_COUNT, 0)
    }

    fun saveReelsCount(context: Context, count: Int) {
        resetIfNewPeriod(context)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putInt(KEY_REELS, count).apply()
    }

    fun saveShortsCount(context: Context, count: Int) {
        resetIfNewPeriod(context)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putInt(KEY_SHORTS, count).apply()
    }

    fun addReelsWatchMs(context: Context, ms: Long) {
        if (ms <= 0) return
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val total = prefs.getLong(KEY_REELS_WATCH_MS, 0L) + ms
        prefs.edit().putLong(KEY_REELS_WATCH_MS, total).apply()
    }

    fun addShortsWatchMs(context: Context, ms: Long) {
        if (ms <= 0) return
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val total = prefs.getLong(KEY_SHORTS_WATCH_MS, 0L) + ms
        prefs.edit().putLong(KEY_SHORTS_WATCH_MS, total).apply()
    }

    fun getReelsCount(context: Context): Int {
        resetIfNewPeriod(context)
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getInt(KEY_REELS, 0)
    }

    fun getShortsCount(context: Context): Int {
        resetIfNewPeriod(context)
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getInt(KEY_SHORTS, 0)
    }

    fun getReelsAvgSeconds(context: Context): Int {
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val count = prefs.getInt(KEY_REELS, 0)
        if (count <= 0) return 0
        val ms = prefs.getLong(KEY_REELS_WATCH_MS, 0L)
        return (ms / count / 1000L).toInt().coerceAtLeast(0)
    }

    fun getShortsAvgSeconds(context: Context): Int {
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val count = prefs.getInt(KEY_SHORTS, 0)
        if (count <= 0) return 0
        val ms = prefs.getLong(KEY_SHORTS_WATCH_MS, 0L)
        return (ms / count / 1000L).toInt().coerceAtLeast(0)
    }

    fun getReelsWatchMs(context: Context): Long {
        resetIfNewPeriod(context)
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_REELS_WATCH_MS, 0L)
    }

    fun getShortsWatchMs(context: Context): Long {
        resetIfNewPeriod(context)
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getLong(KEY_SHORTS_WATCH_MS, 0L)
    }

    fun recordHourlyScroll(context: Context, isReel: Boolean) {
        resetIfNewPeriod(context)
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val key = if (isReel) "hour_reels_$hour" else "hour_shorts_$hour"
        prefs.edit().putInt(key, prefs.getInt(key, 0) + 1).apply()
    }

    fun getHourlyScrollCounts(context: Context): List<Int> {
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return (0 until 24).map { h ->
            prefs.getInt("hour_reels_$h", 0) + prefs.getInt("hour_shorts_$h", 0)
        }
    }

    fun getHourlyReelsCounts(context: Context): List<Int> {
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return (0 until 24).map { h -> prefs.getInt("hour_reels_$h", 0) }
    }

    fun getHourlyShortsCounts(context: Context): List<Int> {
        resetIfNewPeriod(context)
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return (0 until 24).map { h -> prefs.getInt("hour_shorts_$h", 0) }
    }

    fun getHourlyScrollLabels(context: Context): List<String> {
        return (0 until 24).map { h -> formatHour(h) }
    }

    fun getScrollHistory(context: Context, days: Int): List<Map<String, Any>> {
        resetIfNewPeriod(context)
        val result = mutableListOf<Map<String, Any>>()
        val cal = Calendar.getInstance()

        for (i in 0 until days) {
            val dateKey = DailyHistoryStore.periodKey(cal)
            val record = if (i == 0) {
                mapOf(
                    "date" to dateKey,
                    "reels" to getReelsCount(context),
                    "shorts" to getShortsCount(context),
                    "reelsWatchMs" to getReelsWatchMs(context),
                    "shortsWatchMs" to getShortsWatchMs(context),
                )
            } else {
                val archived = DailyHistoryStore.getDay(context, dateKey)
                if (archived != null) {
                    mapOf(
                        "date" to archived.dateKey,
                        "reels" to archived.reels,
                        "shorts" to archived.shorts,
                        "reelsWatchMs" to archived.reelsWatchMs,
                        "shortsWatchMs" to archived.shortsWatchMs,
                    )
                } else {
                    mapOf(
                        "date" to dateKey,
                        "reels" to 0,
                        "shorts" to 0,
                        "reelsWatchMs" to 0L,
                        "shortsWatchMs" to 0L,
                    )
                }
            }
            result.add(record)
            cal.add(Calendar.DAY_OF_MONTH, -1)
        }
        return result
    }

    private fun formatHour(h: Int): String = when {
        h == 0 -> "12 AM"
        h < 12 -> "$h AM"
        h == 12 -> "12 PM"
        else -> "${h - 12} PM"
    }
}
