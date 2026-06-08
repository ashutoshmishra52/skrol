package com.ashutoshmishra.scrollless

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log

object ReelSessionManager {
    private const val TAG = "ScrollLessCount"
    private const val MIN_WATCH_MS = 400L
    private const val MAX_WATCH_MS = 180_000L

    var reelsCount: Int = 0
        private set
    var shortsCount: Int = 0
        private set

    private var overlayMode: TabDetector.FeedMode = TabDetector.FeedMode.NONE
    private var reelWatchStartMs = 0L
    private var shortWatchStartMs = 0L
    private var overlay: ReelOverlayManager? = null
    private var appContext: Context? = null

    private val handler = Handler(Looper.getMainLooper())

    fun init(context: Context) {
        appContext = context.applicationContext
        AppSwitchTracker.ensureInitialized(appContext!!)
        if (overlay == null) {
            overlay = ReelOverlayManager(appContext!!)
        }
        reelsCount = AppSwitchTracker.getReelsCount(appContext!!)
        shortsCount = AppSwitchTracker.getShortsCount(appContext!!)
    }

    fun setOverlayMode(mode: TabDetector.FeedMode) {
        if (overlayMode == mode) {
            if (mode != TabDetector.FeedMode.NONE) refreshOverlay()
            return
        }

        when (overlayMode) {
            TabDetector.FeedMode.REELS -> finalizeReelWatch()
            TabDetector.FeedMode.SHORTS -> finalizeShortWatch()
            TabDetector.FeedMode.NONE -> {}
        }

        overlayMode = mode
        when (mode) {
            TabDetector.FeedMode.REELS -> startReelWatchTimer()
            TabDetector.FeedMode.SHORTS -> startShortWatchTimer()
            TabDetector.FeedMode.NONE -> overlay?.hide()
        }
        if (mode != TabDetector.FeedMode.NONE) refreshOverlay()
    }

    fun commitReel() {
        finalizeReelWatch()
        reelsCount++
        persist()
        AppSwitchTracker.recordHourlyScroll(appContext!!, isReel = true)
        startReelWatchTimer()
        refreshOverlay()
        Log.i(TAG, "COUNT_SAVED reels=$reelsCount")
        Log.i(TAG, "OVERLAY_UPDATED reels=$reelsCount")
    }

    fun commitShort() {
        finalizeShortWatch()
        shortsCount++
        persist()
        AppSwitchTracker.recordHourlyScroll(appContext!!, isReel = false)
        startShortWatchTimer()
        refreshOverlay()
        Log.i(TAG, "COUNT_SAVED shorts=$shortsCount")
        Log.i(TAG, "OVERLAY_UPDATED shorts=$shortsCount")
    }

    private fun startReelWatchTimer() {
        reelWatchStartMs = System.currentTimeMillis()
    }

    private fun startShortWatchTimer() {
        shortWatchStartMs = System.currentTimeMillis()
    }

    private fun finalizeReelWatch() {
        val ctx = appContext ?: return
        if (reelWatchStartMs <= 0) return
        val elapsed = System.currentTimeMillis() - reelWatchStartMs
        reelWatchStartMs = 0L
        if (elapsed in MIN_WATCH_MS..MAX_WATCH_MS) {
            AppSwitchTracker.addReelsWatchMs(ctx, elapsed)
        }
    }

    private fun finalizeShortWatch() {
        val ctx = appContext ?: return
        if (shortWatchStartMs <= 0) return
        val elapsed = System.currentTimeMillis() - shortWatchStartMs
        shortWatchStartMs = 0L
        if (elapsed in MIN_WATCH_MS..MAX_WATCH_MS) {
            AppSwitchTracker.addShortsWatchMs(ctx, elapsed)
        }
    }

    fun persist() {
        val ctx = appContext ?: return
        AppSwitchTracker.saveReelsCount(ctx, reelsCount)
        AppSwitchTracker.saveShortsCount(ctx, shortsCount)
        // Keep in-memory in sync with persisted values.
        reelsCount = AppSwitchTracker.getReelsCount(ctx)
        shortsCount = AppSwitchTracker.getShortsCount(ctx)
        FeedStatsEventBridge.notifyStatsChanged(ctx)
    }

    fun refreshOverlay() {
        if (overlay?.canDrawOverlay() != true) return
        when (overlayMode) {
            TabDetector.FeedMode.REELS -> overlay?.update(reelsCount)
            TabDetector.FeedMode.SHORTS -> overlay?.update(shortsCount)
            TabDetector.FeedMode.NONE -> overlay?.hide()
        }
    }

    fun reset() {
        overlay?.hide()
    }
}
