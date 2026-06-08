package com.ashutoshmishra.scrollless.detection

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.ashutoshmishra.scrollless.TabDetector

/**
 * Captures accessibility tree snapshot for Reels detection debugging.
 */
object NodeTreeDumper {
    private const val TAG = "ScrollLessTree"
    private const val MAX_TEXT_ITEMS = 12
    private const val MAX_DESC_ITEMS = 12
    private const val THROTTLE_MS = 500L

    private var lastCaptureMs = 0L

    fun captureOnInstagramEvent(service: AccessibilityService, event: AccessibilityEvent) {
        if (event.packageName?.toString() != TabDetector.PKG_INSTAGRAM) return
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOWS_CHANGED -> {
                val now = System.currentTimeMillis()
                if (now - lastCaptureMs < THROTTLE_MS) return
                lastCaptureMs = now
                capture(service, event)
            }
        }
    }

    private fun capture(service: AccessibilityService, event: AccessibilityEvent) {
        val root = TabDetector.getActiveRoot(service)
        if (root == null) {
            HybridDebugStore.instagramPackageActive = true
            HybridDebugStore.nodeCount = 0
            HybridDebugStore.hierarchyDepth = 0
            return
        }

        val texts = mutableListOf<String>()
        val descs = mutableListOf<String>()
        val stats = TreeStats()
        walk(root, texts, descs, 0, stats)

        HybridDebugStore.instagramPackageActive = true
        HybridDebugStore.currentPackage = TabDetector.PKG_INSTAGRAM
        HybridDebugStore.currentActivity = event.className?.toString() ?: root.className?.toString() ?: ""
        HybridDebugStore.visibleTexts = texts.take(MAX_TEXT_ITEMS).joinToString(" | ")
        HybridDebugStore.visibleDescriptions = descs.take(MAX_DESC_ITEMS).joinToString(" | ")
        HybridDebugStore.nodeCount = stats.nodeCount
        HybridDebugStore.hierarchyDepth = stats.maxDepth

        FeedSessionDetector.evaluateAndDebugReels(root)

        Log.d(
            TAG,
            "IG tree nodes=${stats.nodeCount} depth=${stats.maxDepth} " +
                "activity=${HybridDebugStore.currentActivity} " +
                "reelsActive=${HybridDebugStore.reelsActive} " +
                "reject=${HybridDebugStore.reelsRejectCode}",
        )
    }

    private class TreeStats {
        var nodeCount = 0
        var maxDepth = 0
    }

    private fun walk(
        node: AccessibilityNodeInfo?,
        texts: MutableList<String>,
        descs: MutableList<String>,
        depth: Int,
        stats: TreeStats,
    ) {
        if (node == null || depth > 24) return
        stats.nodeCount++
        if (depth > stats.maxDepth) stats.maxDepth = depth

        val text = node.text?.toString()?.trim() ?: ""
        val desc = node.contentDescription?.toString()?.trim() ?: ""
        if (text.length in 2..80 && texts.size < MAX_TEXT_ITEMS * 2) texts.add(text)
        if (desc.length in 2..80 && descs.size < MAX_DESC_ITEMS * 2) descs.add(desc)

        for (i in 0 until node.childCount) {
            walk(node.getChild(i), texts, descs, depth + 1, stats)
        }
    }
}
