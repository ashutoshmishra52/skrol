package com.ashutoshmishra.scrollless

import android.content.Context
import org.json.JSONObject
import java.util.Calendar

/**
 * Archives daily reels/shorts counts before midnight rollover.
 */
object DailyHistoryStore {
    private const val PREFS = "scrollless_daily_history"
    private const val KEY_PREFIX = "day_"

    data class DayRecord(
        val dateKey: String,
        val reels: Int,
        val shorts: Int,
        val reelsWatchMs: Long,
        val shortsWatchMs: Long,
    )

    fun archiveDay(
        context: Context,
        dateKey: String,
        reels: Int,
        shorts: Int,
        reelsWatchMs: Long,
        shortsWatchMs: Long,
    ) {
        if (dateKey.isBlank()) return
        val json = JSONObject()
            .put("reels", reels)
            .put("shorts", shorts)
            .put("reelsWatchMs", reelsWatchMs)
            .put("shortsWatchMs", shortsWatchMs)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PREFIX + dateKey, json.toString())
            .apply()
        pruneOldEntries(context)
    }

    fun getDay(context: Context, dateKey: String): DayRecord? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_PREFIX + dateKey, null) ?: return null
        return parse(dateKey, raw)
    }

    fun getLastDays(context: Context, days: Int): List<DayRecord> {
        val result = mutableListOf<DayRecord>()
        val cal = Calendar.getInstance()
        for (i in 0 until days) {
            val key = periodKey(cal)
            getDay(context, key)?.let { result.add(it) }
            cal.add(Calendar.DAY_OF_MONTH, -1)
        }
        return result
    }

    fun periodKey(cal: Calendar = Calendar.getInstance()): String {
        val y = cal.get(Calendar.YEAR)
        val m = cal.get(Calendar.MONTH) + 1
        val d = cal.get(Calendar.DAY_OF_MONTH)
        return String.format("%04d-%02d-%02d", y, m, d)
    }

    private fun parse(dateKey: String, raw: String): DayRecord? {
        return try {
            val json = JSONObject(raw)
            DayRecord(
                dateKey = dateKey,
                reels = json.optInt("reels", 0),
                shorts = json.optInt("shorts", 0),
                reelsWatchMs = json.optLong("reelsWatchMs", 0L),
                shortsWatchMs = json.optLong("shortsWatchMs", 0L),
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun pruneOldEntries(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_MONTH, -30)
        val cutoff = periodKey(cal)
        val editor = prefs.edit()
        for (key in prefs.all.keys) {
            if (!key.startsWith(KEY_PREFIX)) continue
            val dateKey = key.removePrefix(KEY_PREFIX)
            if (dateKey < cutoff) editor.remove(key)
        }
        editor.apply()
    }
}
