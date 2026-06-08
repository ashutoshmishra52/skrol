package com.ashutoshmishra.scrollless.detection

import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Single detection pipeline for Reels and Shorts.
 * Shorts path is the reference — Reels uses the same evaluateSession() flow.
 */
object FeedSessionDetector {
    private const val TAG = "ScrollLessDetect"

    data class SessionResult(
        val active: Boolean,
        val rejectCode: String = "",
        val rejectDetail: String = "",
        val acceptReason: String = "",
    )

    private data class FeedConfig(
        val feedKey: String,
        val rejectPrefix: String,
        val tabName: String,
        val blockTabs: List<String>,
        val blockLongForm: (AccessibilityNodeInfo) -> Boolean,
        val hasResourceIds: (AccessibilityNodeInfo) -> Boolean,
        val hasDefiniteUi: (AccessibilityNodeInfo) -> Boolean,
        val countActions: (AccessibilityNodeInfo) -> Int,
    )

    private val SHORTS_CONFIG = FeedConfig(
        feedKey = "shorts",
        rejectPrefix = "SHORTS_REJECTED",
        tabName = "shorts",
        blockTabs = listOf("home", "subscriptions", "library", "explore"),
        blockLongForm = TabDetectorHelper::hasLongFormWatchPlayer,
        hasResourceIds = TabDetectorHelper::hasShortsResourceIds,
        hasDefiniteUi = TabDetectorHelper::hasDefiniteShortsUi,
        countActions = TabDetectorHelper::countSideActions,
    )

    private val REELS_CONFIG = FeedConfig(
        feedKey = "reels",
        rejectPrefix = "REELS_REJECTED",
        tabName = "reels",
        blockTabs = listOf("home", "profile", "search", "explore", "create"),
        blockLongForm = { false },
        hasResourceIds = TabDetectorHelper::hasReelsResourceIds,
        hasDefiniteUi = TabDetectorHelper::hasDefiniteReelsUi,
        countActions = TabDetectorHelper::countSideActions,
    )

    fun isShortsActive(root: AccessibilityNodeInfo): Boolean = evaluateShorts(root).active

    fun isReelsActive(root: AccessibilityNodeInfo): Boolean = evaluateReels(root).active

    fun evaluateShorts(root: AccessibilityNodeInfo): SessionResult = evaluateSession(root, SHORTS_CONFIG)

    fun evaluateReels(root: AccessibilityNodeInfo): SessionResult = evaluateSession(root, REELS_CONFIG)

    fun evaluateAndDebugReels(root: AccessibilityNodeInfo?): SessionResult {
        if (root == null) {
            val result = inactive("REELS_REJECTED_NODE_MISSING", "root is null")
            applyReelsDebug(result)
            return result
        }
        val result = evaluateReels(root)
        applyReelsDebug(result)
        if (!result.active) {
            Log.w(TAG, "${result.rejectCode}: ${result.rejectDetail}")
        } else {
            Log.d(TAG, "Reels accepted: ${result.acceptReason}")
        }
        return result
    }

    private fun evaluateSession(root: AccessibilityNodeInfo, config: FeedConfig): SessionResult {
        for (tab in config.blockTabs) {
            if (TabDetectorHelper.isTabSelected(root, tab)) {
                return inactive(
                    config,
                    "TAB_NOT_ACTIVE",
                    "${tab} tab is selected",
                )
            }
        }

        if (config.blockLongForm(root)) {
            return inactive(config, "INVALID_LAYOUT", "long-form player visible")
        }

        if (TabDetectorHelper.isTabSelected(root, config.tabName)) {
            return active(config, "${config.tabName}_tab_selected")
        }

        if (config.hasResourceIds(root)) {
            return active(config, "${config.tabName}_resource_id")
        }

        if (config.hasDefiniteUi(root)) {
            return active(config, "${config.tabName}_definite_ui")
        }

        if (TabDetectorHelper.hasVisibleTab(root, config.tabName) &&
            TabDetectorHelper.hasVerticalScrollable(root)
        ) {
            return active(config, "visible_tab_and_scroll")
        }

        if (TabDetectorHelper.hasVerticalScrollable(root) && config.countActions(root) >= 1) {
            return active(config, "scroll_and_actions")
        }

        if (!TabDetectorHelper.hasVerticalScrollable(root)) {
            return inactive(config, "NO_FULLSCREEN", "no vertical scrollable container")
        }

        return inactive(config, "NODE_MISSING", "layout does not match ${config.feedKey} session")
    }

    private fun active(config: FeedConfig, reason: String) = SessionResult(
        active = true,
        acceptReason = reason,
    )

    private fun inactive(config: FeedConfig, suffix: String, detail: String) = SessionResult(
        active = false,
        rejectCode = "${config.rejectPrefix}_$suffix",
        rejectDetail = detail,
    )

    private fun inactive(code: String, detail: String) = SessionResult(
        active = false,
        rejectCode = code,
        rejectDetail = detail,
    )

    private fun applyReelsDebug(result: SessionResult) {
        HybridDebugStore.reelsActive = result.active
        HybridDebugStore.reelsRejectCode = if (result.active) "" else result.rejectCode
        HybridDebugStore.reelsRejectDetail = if (result.active) "" else result.rejectDetail
        HybridDebugStore.reelsAcceptReason = result.acceptReason
    }
}
