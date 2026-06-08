package com.ashutoshmishra.scrollless

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import java.util.Calendar

object UsageCalculator {

    data class AppUsage(val packageName: String, val label: String, val minutes: Int, val category: String)

    data class SocialBreakdown(
        val instagramMinutes: Int,
        val youtubeMinutes: Int,
        val facebookMinutes: Int,
        val xMinutes: Int,
        val snapchatMinutes: Int,
        val otherMinutes: Int,
        val totalMinutes: Int,
    )

    fun computeTodayUsage(context: Context): List<AppUsage> {
        val (startMs, endMs) = todayBounds()
        return computeUsage(context, startMs, endMs)
    }

    fun computeSocialBreakdown(context: Context): SocialBreakdown {
        val usage = computeTodayUsage(context)
        var instagram = 0
        var youtube = 0
        var facebook = 0
        var x = 0
        var snapchat = 0
        var other = 0

        for (app in usage) {
            when (app.category) {
                "instagram" -> instagram += app.minutes
                "youtube" -> youtube += app.minutes
                "facebook" -> facebook += app.minutes
                "x" -> x += app.minutes
                "snapchat" -> snapchat += app.minutes
                else -> other += app.minutes
            }
        }

        val total = instagram + youtube + facebook + x + snapchat + other
        return SocialBreakdown(
            instagramMinutes = instagram,
            youtubeMinutes = youtube,
            facebookMinutes = facebook,
            xMinutes = x,
            snapchatMinutes = snapchat,
            otherMinutes = other,
            totalMinutes = total,
        )
    }

    fun totalScreenMinutes(context: Context): Int {
        return computeSocialBreakdown(context).totalMinutes
    }

    private fun todayBounds(): Pair<Long, Long> {
        val cal = Calendar.getInstance()
        val endMs = cal.timeInMillis
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis to endMs
    }

    private fun computeUsage(context: Context, startMs: Long, endMs: Long): List<AppUsage> {
        if (!PlatformUtils.hasUsagePermission(context)) return emptyList()

        val msByPackage = foregroundMsFromEvents(context, startMs, endMs)
        val result = mutableListOf<AppUsage>()

        for ((pkg, ms) in msByPackage) {
            if (!PackageFilters.isSocialApp(pkg)) continue
            val minutes = (ms / 60_000.0).toInt()
            if (minutes <= 0) continue
            result.add(
                AppUsage(
                    packageName = pkg,
                    label = PackageFilters.getAppLabel(context, pkg),
                    minutes = minutes.coerceAtMost(1440),
                    category = PackageFilters.socialCategory(pkg),
                ),
            )
        }

        return result.sortedByDescending { it.minutes }
    }

    private fun foregroundMsFromEvents(
        context: Context,
        startMs: Long,
        endMs: Long,
    ): Map<String, Long> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usm.queryEvents(startMs, endMs)
        val event = UsageEvents.Event()

        val totals = mutableMapOf<String, Long>()
        var activePkg: String? = null
        var activeSince = 0L

        fun closeSession(untilMs: Long) {
            val pkg = activePkg ?: return
            if (activeSince <= 0) return
            val duration = untilMs - activeSince
            if (duration >= 1_000L) {
                totals[pkg] = (totals[pkg] ?: 0L) + duration
            }
            activePkg = null
            activeSince = 0L
        }

        fun isForeground(type: Int): Boolean {
            return type == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                    type == UsageEvents.Event.ACTIVITY_RESUMED)
        }

        fun isBackground(type: Int): Boolean {
            return type == UsageEvents.Event.MOVE_TO_BACKGROUND ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                    type == UsageEvents.Event.ACTIVITY_PAUSED)
        }

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            if (pkg == context.packageName) continue
            val ts = event.timeStamp.coerceIn(startMs, endMs)

            when {
                isForeground(event.eventType) -> {
                    closeSession(ts)
                    activePkg = pkg
                    activeSince = ts
                }
                isBackground(event.eventType) -> {
                    if (pkg == activePkg) closeSession(ts)
                }
            }
        }

        if (activePkg != null && activeSince > 0) {
            closeSession(endMs)
        }

        return totals
    }
}
