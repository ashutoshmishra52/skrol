package com.ashutoshmishra.scrollless

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * Pushes reel/short count changes to Flutter instantly (no polling delay).
 */
object FeedStatsEventBridge {
    private const val TAG = "ScrollLessCount"
    private var sink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())

    fun setSink(eventSink: EventChannel.EventSink?) {
        sink = eventSink
    }

    fun notifyStatsChanged(context: Context) {
        val ctx = context.applicationContext
        AppSwitchTracker.ensureInitialized(ctx)
        ReelSessionManager.init(ctx)
        val payload = mapOf(
            "reels" to AppSwitchTracker.getReelsCount(ctx),
            "shorts" to AppSwitchTracker.getShortsCount(ctx),
            "reelsAvgSeconds" to AppSwitchTracker.getReelsAvgSeconds(ctx),
            "shortsAvgSeconds" to AppSwitchTracker.getShortsAvgSeconds(ctx),
            "reelsWatchMs" to AppSwitchTracker.getReelsWatchMs(ctx),
            "shortsWatchMs" to AppSwitchTracker.getShortsWatchMs(ctx),
            "appSwitches" to AppSwitchTracker.getSwitchCount(ctx),
            "hourlyScrollCounts" to AppSwitchTracker.getHourlyScrollCounts(ctx),
            "hourlyScrollLabels" to AppSwitchTracker.getHourlyScrollLabels(ctx),
        )
        handler.post {
            sink?.success(payload)
            Log.i(TAG, "DASHBOARD_UPDATED reels=${payload["reels"]} shorts=${payload["shorts"]}")
        }
    }
}
