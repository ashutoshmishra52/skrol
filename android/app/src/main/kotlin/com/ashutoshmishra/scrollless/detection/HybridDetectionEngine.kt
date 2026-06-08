package com.ashutoshmishra.scrollless.detection

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.ashutoshmishra.scrollless.ReelSessionManager
import com.ashutoshmishra.scrollless.TabDetector

/**
 * Unified hash-based counter for Reels and Shorts — identical code path.
 * Rules: session active → hash changed → not same as lastHash → 800ms debounce → count +1.
 * During debounce: absorb hash changes (update lastHash, never queue, never batch).
 */
object HybridDetectionEngine {
    private const val TAG = "ScrollLessCount"
    private const val DEBOUNCE_MS = 800L
    private const val SESSION_GRACE_MS = 1200L
    private const val BURST_WINDOW_MS = 2000L

    private var activeFeed: TabDetector.FeedMode = TabDetector.FeedMode.NONE
    private var feedGraceUntilMs = 0L
    private var lastHash = ""
    private var lastCountTime = 0L
    private var lastHashChangeTime = 0L
    private var seeded = false
    private var burstWindowStart = 0L
    private var commitsInBurstWindow = 0

    fun onServiceConnected(service: AccessibilityService) {
        Log.i(TAG, "Unified hash counter ready (Reels = Shorts pipeline)")
        refreshSession(service)
        syncTotals(service)
    }

    fun onAnyEvent(service: AccessibilityService, event: AccessibilityEvent) {
        val pkg = event.packageName?.toString() ?: return
        if (pkg != TabDetector.PKG_INSTAGRAM && pkg != TabDetector.PKG_YOUTUBE) return

        HybridDebugStore.lastEventType = eventTypeName(event.eventType)
        HybridDebugStore.currentApp = when (pkg) {
            TabDetector.PKG_INSTAGRAM -> "Instagram"
            TabDetector.PKG_YOUTUBE -> "YouTube"
            else -> pkg
        }

        refreshSession(service)
        if (!isSessionForPackage(pkg)) {
            updateOverlay(service)
            return
        }

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOWS_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> processHashChange(service)
        }

        updateOverlay(service)
    }

    fun onAppBackgrounded() {
        activeFeed = TabDetector.FeedMode.NONE
        feedGraceUntilMs = 0L
        resetDetectionState()
        HybridDebugStore.reelsActive = false
        HybridDebugStore.shortsActive = false
        HybridDebugStore.instagramPackageActive = false
        HybridDebugStore.currentScreen = "idle"
        ReelSessionManager.setOverlayMode(TabDetector.FeedMode.NONE)
    }

    private fun refreshSession(service: AccessibilityService) {
        val now = System.currentTimeMillis()
        val mode = TabDetector.detectMode(service)
        val rawActive = mode == TabDetector.FeedMode.REELS || mode == TabDetector.FeedMode.SHORTS
        if (rawActive) feedGraceUntilMs = now + SESSION_GRACE_MS

        val wasFeed = activeFeed
        val nextFeed = when {
            rawActive -> mode
            wasFeed != TabDetector.FeedMode.NONE && now < feedGraceUntilMs -> wasFeed
            else -> TabDetector.FeedMode.NONE
        }

        updateDebugSession(nextFeed)

        if (nextFeed != TabDetector.FeedMode.NONE && wasFeed == TabDetector.FeedMode.NONE) {
            Log.i(TAG, "${feedLabel(nextFeed)} session started")
            seedHash(service)
        } else if (nextFeed == TabDetector.FeedMode.NONE && wasFeed != TabDetector.FeedMode.NONE) {
            resetDetectionState()
        } else if (nextFeed != wasFeed && nextFeed != TabDetector.FeedMode.NONE) {
            resetDetectionState()
            seedHash(service)
        }

        activeFeed = nextFeed
    }

    private fun seedHash(service: AccessibilityService) {
        val root = TabDetector.getActiveRoot(service) ?: return
        val hash = NodeHashGenerator.generate(root)
        if (hash.isEmpty()) return
        lastHash = hash
        lastHashChangeTime = System.currentTimeMillis()
        seeded = true
        updateDebugHash(hash, "")
        clearPendingDebug()
    }

    private fun processHashChange(service: AccessibilityService) {
        val root = TabDetector.getActiveRoot(service) ?: return
        val hash = NodeHashGenerator.generate(root)
        if (hash.isEmpty()) return

        val previousHash = lastHash
        val now = System.currentTimeMillis()
        updateDebugHash(hash, previousHash)

        if (hash == lastHash) return

        lastHashChangeTime = now
        setLastHashChangeDebug(now)

        if (!seeded) {
            lastHash = hash
            seeded = true
            clearPendingDebug()
            logDetected("seed", hash)
            return
        }

        val elapsed = now - lastCountTime
        if (elapsed < DEBOUNCE_MS) {
            // Anti-burst: absorb intermediate hash — never queue, never batch
            lastHash = hash
            incrementAbsorbedDebug()
            logDetected("absorbed_debounce_${elapsed}ms", hash)
            return
        }

        // One transition → one count. Clear state before commit.
        lastHash = hash
        lastCountTime = now
        clearPendingDebug()
        setDebugCountMeta(now, "hash_change")
        logDetected("transition", hash)

        when (activeFeed) {
            TabDetector.FeedMode.REELS -> incrementCount(service, isReel = true, hash, previousHash, now)
            TabDetector.FeedMode.SHORTS -> incrementCount(service, isReel = false, hash, previousHash, now)
            TabDetector.FeedMode.NONE -> return
        }
    }

    private fun incrementCount(
        service: AccessibilityService,
        isReel: Boolean,
        hash: String,
        previousHash: String,
        now: Long,
    ) {
        trackBurstWindow(now, hash, previousHash, isReel)

        if (isReel) {
            ReelSessionManager.commitReel()
            Log.i(TAG, "COUNT_INCREMENTED reel total=${ReelSessionManager.reelsCount} hash=$hash")
        } else {
            ReelSessionManager.commitShort()
            Log.i(TAG, "COUNT_INCREMENTED short total=${ReelSessionManager.shortsCount} hash=$hash")
        }

        Log.i(TAG, "COUNT_SAVED")
        Log.i(TAG, "OVERLAY_UPDATED")
        Log.i(TAG, "DASHBOARD_UPDATED")
        syncTotals(service)
    }

    private fun trackBurstWindow(now: Long, hash: String, previousHash: String, isReel: Boolean) {
        if (now - burstWindowStart > BURST_WINDOW_MS) {
            burstWindowStart = now
            commitsInBurstWindow = 1
        } else {
            commitsInBurstWindow++
        }

        if (commitsInBurstWindow > 1) {
            val reason = "BURST: $commitsInBurstWindow commits in ${now - burstWindowStart}ms " +
                "hash=$hash prev=$previousHash"
            Log.w(TAG, reason)
            if (isReel) {
                HybridDebugStore.reelsBurstWarning = reason
            } else {
                HybridDebugStore.shortsBurstWarning = reason
            }
        }
    }

    private fun resetDetectionState() {
        lastHash = ""
        lastCountTime = 0L
        lastHashChangeTime = 0L
        seeded = false
        burstWindowStart = 0L
        commitsInBurstWindow = 0
        clearPendingDebug()
    }

    private fun clearPendingDebug() {
        HybridDebugStore.reelsPendingEvents = 0
        HybridDebugStore.shortsPendingEvents = 0
        HybridDebugStore.reelsEventQueueSize = 0
        HybridDebugStore.shortsEventQueueSize = 0
        HybridDebugStore.reelsPendingHash = ""
        HybridDebugStore.shortsPendingHash = ""
        HybridDebugStore.reelsAbsorbedTransitions = 0
        HybridDebugStore.shortsAbsorbedTransitions = 0
    }

    private fun incrementAbsorbedDebug() {
        HybridDebugStore.reelsEventQueueSize = 0
        HybridDebugStore.shortsEventQueueSize = 0
        HybridDebugStore.reelsPendingEvents = 0
        HybridDebugStore.shortsPendingEvents = 0
        when (activeFeed) {
            TabDetector.FeedMode.REELS -> {
                HybridDebugStore.reelsAbsorbedTransitions++
            }
            TabDetector.FeedMode.SHORTS -> {
                HybridDebugStore.shortsAbsorbedTransitions++
            }
            TabDetector.FeedMode.NONE -> {}
        }
    }

    private fun setLastHashChangeDebug(now: Long) {
        when (activeFeed) {
            TabDetector.FeedMode.REELS -> HybridDebugStore.reelsLastHashChangeTime = now
            TabDetector.FeedMode.SHORTS -> HybridDebugStore.shortsLastHashChangeTime = now
            TabDetector.FeedMode.NONE -> {}
        }
    }

    private fun logDetected(phase: String, hash: String) {
        val label = feedLabel(activeFeed)
        Log.d(TAG, "REEL_DETECTED $label phase=$phase hash=$hash")
    }

    private fun isSessionForPackage(pkg: String): Boolean = when (activeFeed) {
        TabDetector.FeedMode.REELS -> pkg == TabDetector.PKG_INSTAGRAM
        TabDetector.FeedMode.SHORTS -> pkg == TabDetector.PKG_YOUTUBE
        TabDetector.FeedMode.NONE -> false
    }

    private fun updateDebugSession(feed: TabDetector.FeedMode) {
        HybridDebugStore.reelsActive = feed == TabDetector.FeedMode.REELS
        HybridDebugStore.shortsActive = feed == TabDetector.FeedMode.SHORTS
        HybridDebugStore.currentScreen = when (feed) {
            TabDetector.FeedMode.REELS -> "Instagram Reels"
            TabDetector.FeedMode.SHORTS -> "YouTube Shorts"
            TabDetector.FeedMode.NONE -> when (HybridDebugStore.currentApp) {
                "Instagram" -> "Instagram (other)"
                "YouTube" -> "YouTube (other)"
                else -> "idle"
            }
        }
    }

    private fun updateDebugHash(hash: String, previousHash: String) {
        when (activeFeed) {
            TabDetector.FeedMode.REELS -> {
                HybridDebugStore.reelsPreviousHash = previousHash
                HybridDebugStore.reelsCurrentHash = hash
            }
            TabDetector.FeedMode.SHORTS -> {
                HybridDebugStore.shortsPreviousHash = previousHash
                HybridDebugStore.shortsCurrentHash = hash
            }
            TabDetector.FeedMode.NONE -> {}
        }
    }

    private fun setDebugCountMeta(now: Long, reason: String) {
        when (activeFeed) {
            TabDetector.FeedMode.REELS -> {
                HybridDebugStore.reelsLastCountTime = now
                HybridDebugStore.reelsLastTrigger = reason
                HybridDebugStore.reelsBurstWarning = ""
                HybridDebugStore.reelsAbsorbedTransitions = 0
            }
            TabDetector.FeedMode.SHORTS -> {
                HybridDebugStore.shortsLastCountTime = now
                HybridDebugStore.shortsLastTrigger = reason
                HybridDebugStore.shortsBurstWarning = ""
                HybridDebugStore.shortsAbsorbedTransitions = 0
            }
            TabDetector.FeedMode.NONE -> {}
        }
    }

    private fun syncTotals(@Suppress("UNUSED_PARAMETER") service: AccessibilityService) {
        HybridDebugStore.totalReels = ReelSessionManager.reelsCount
        HybridDebugStore.totalShorts = ReelSessionManager.shortsCount
    }

    private fun updateOverlay(@Suppress("UNUSED_PARAMETER") service: AccessibilityService) {
        ReelSessionManager.setOverlayMode(activeFeed)
    }

    private fun feedLabel(feed: TabDetector.FeedMode): String = when (feed) {
        TabDetector.FeedMode.REELS -> "Reels"
        TabDetector.FeedMode.SHORTS -> "Shorts"
        TabDetector.FeedMode.NONE -> "None"
    }

    private fun eventTypeName(type: Int): String = when (type) {
        AccessibilityEvent.TYPE_VIEW_SCROLLED -> "VIEW_SCROLLED"
        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> "CONTENT_CHANGED"
        AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> "WINDOW_STATE"
        AccessibilityEvent.TYPE_WINDOWS_CHANGED -> "WINDOWS_CHANGED"
        else -> "type_$type"
    }
}
