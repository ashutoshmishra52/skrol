package com.ashutoshmishra.scrollless.detection

import android.view.accessibility.AccessibilityNodeInfo
import java.util.Locale

/**
 * Shared node-walking helpers used by FeedSessionDetector (same tree for Reels & Shorts).
 */
internal object TabDetectorHelper {

    fun isTabSelected(root: AccessibilityNodeInfo, tabName: String): Boolean {
        return findSelectedTab(root, tabName)
    }

    fun isReelsTabSelected(root: AccessibilityNodeInfo): Boolean {
        return findReelsTabByDescription(root) || findReelsNavItemSelected(root)
    }

    fun hasVisibleTab(root: AccessibilityNodeInfo, tabName: String): Boolean {
        return findVisibleTab(root, tabName)
    }

    fun hasVerticalScrollable(root: AccessibilityNodeInfo): Boolean {
        return findVerticalScrollable(root)
    }

    fun countSideActions(root: AccessibilityNodeInfo): Int {
        val found = mutableSetOf<String>()
        collectSideActions(root, found, 0)
        return found.size
    }

    fun hasShortsResourceIds(root: AccessibilityNodeInfo): Boolean {
        return findResourceIds(root, "shorts")
    }

    fun hasReelsResourceIds(root: AccessibilityNodeInfo): Boolean {
        return findReelsResourceIds(root)
    }

    fun hasDefiniteShortsUi(root: AccessibilityNodeInfo): Boolean {
        return findDefiniteShortsUi(root)
    }

    fun hasDefiniteReelsUi(root: AccessibilityNodeInfo): Boolean {
        return findDefiniteReelsUi(root)
    }

    fun hasLongFormWatchPlayer(root: AccessibilityNodeInfo): Boolean {
        return findLongFormWatchPlayer(root)
    }

    fun isHomeFeedWithoutReels(root: AccessibilityNodeInfo): Boolean {
        if (isTabSelected(root, "home")) return false
        return findHomeFeedFragment(root) && !hasReelsPlayerIndicators(root)
    }

    fun reelsExtraAcceptReason(root: AccessibilityNodeInfo): String? {
        if (findReelsTabByDescription(root)) return "reels_tab_by_description"
        if (findReelsNavItemSelected(root)) return "reels_nav_selected"
        if (hasReelsPlayerIndicators(root)) return "reels_player_indicators"
        if (findReelsFragment(root)) return "reels_fragment"
        return null
    }

    private fun findSelectedTab(node: AccessibilityNodeInfo?, tabName: String, depth: Int = 0): Boolean {
        if (node == null || depth > 18) return false
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val tabMatch = text == tabName ||
            desc == tabName ||
            desc.startsWith("$tabName,") ||
            desc.contains("$tabName, tab") ||
            desc.contains("$tabName tab") ||
            (desc.contains("tab") && desc.contains(tabName)) ||
            (tabName == "reels" && (desc.contains("reel,") || desc == "reel")) ||
            (tabName == "shorts" && desc.contains("shorts")) ||
            (tabName == "home" && (desc.startsWith("home,") || desc.contains("home, tab")))
        if (tabMatch && isNodeOrParentSelected(node)) return true
        for (i in 0 until node.childCount) {
            if (findSelectedTab(node.getChild(i), tabName, depth + 1)) return true
        }
        return false
    }

    private fun findVisibleTab(node: AccessibilityNodeInfo?, tabName: String, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        if (text == tabName || desc.contains(tabName)) return true
        for (i in 0 until node.childCount) {
            if (findVisibleTab(node.getChild(i), tabName, depth + 1)) return true
        }
        return false
    }

    private fun findResourceIds(node: AccessibilityNodeInfo?, keyword: String, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val viewId = node.viewIdResourceName?.lowercase(Locale.US) ?: ""
        if (viewId.contains(keyword) &&
            (viewId.contains("tab") || viewId.contains("player") || viewId.contains("fragment"))
        ) {
            return true
        }
        for (i in 0 until node.childCount) {
            if (findResourceIds(node.getChild(i), keyword, depth + 1)) return true
        }
        return false
    }

    private fun findReelsResourceIds(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val viewId = node.viewIdResourceName?.lowercase(Locale.US) ?: ""
        if (viewId.contains("clips_viewer") || viewId.contains("reels_viewer") ||
            viewId.contains("reel_viewer") || viewId.contains("clips_tab") ||
            (viewId.contains("reel") && viewId.contains("tab"))
        ) {
            return true
        }
        for (i in 0 until node.childCount) {
            if (findReelsResourceIds(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findDefiniteShortsUi(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val cls = node.className?.toString()?.lowercase(Locale.US) ?: ""
        if (desc.contains("remix") && desc.contains("short")) return true
        if (desc.contains("create a short")) return true
        if (cls.contains("shorts") && (cls.contains("player") || cls.contains("fragment"))) return true
        for (i in 0 until node.childCount) {
            if (findDefiniteShortsUi(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findDefiniteReelsUi(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val cls = node.className?.toString()?.lowercase(Locale.US) ?: ""
        if (desc.contains("reel by ") || desc.contains("reels by ")) return true
        if (cls.contains("reel") && (cls.contains("player") || cls.contains("fragment") || cls.contains("viewer"))) {
            return true
        }
        if (cls.contains("clips") && (cls.contains("viewer") || cls.contains("fragment"))) return true
        for (i in 0 until node.childCount) {
            if (findDefiniteReelsUi(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findLongFormWatchPlayer(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        val combined = "$desc $text"
        if (combined.contains("video player")) return true
        if (combined.contains("seek") && combined.contains("slider")) return true
        if (combined.contains("playback speed")) return true
        if (combined.contains("chapter")) return true
        for (i in 0 until node.childCount) {
            if (findLongFormWatchPlayer(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findVerticalScrollable(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 20) return false
        val cls = node.className?.toString()?.lowercase(Locale.US) ?: ""
        if (node.isScrollable) {
            if (cls.contains("viewpager") || cls.contains("recyclerview") ||
                cls.contains("scrollview") || cls.contains("viewpager2") ||
                depth >= 1
            ) {
                return true
            }
        }
        for (i in 0 until node.childCount) {
            if (findVerticalScrollable(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findHomeFeedFragment(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val cls = node.className?.toString()?.lowercase(Locale.US) ?: ""
        if ((cls.contains("feed") || cls.contains("timeline") || cls.contains("mainfeed")) &&
            cls.contains("fragment") && !cls.contains("reel")
        ) {
            return true
        }
        for (i in 0 until node.childCount) {
            if (findHomeFeedFragment(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findReelsFragment(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val cls = node.className?.toString()?.lowercase(Locale.US) ?: ""
        if (cls.contains("reel") &&
            (cls.contains("fragment") || cls.contains("viewer") || cls.contains("tab"))
        ) {
            if (!cls.contains("thumbnail") && !cls.contains("preview") && !cls.contains("grid")) {
                return true
            }
        }
        for (i in 0 until node.childCount) {
            if (findReelsFragment(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findReelsTabByDescription(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 20) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        val isReelsLabel = desc.contains("reels") || text == "reels" ||
            desc == "reel" || text == "reel" || desc.contains("reel tab") ||
            desc.contains("reel,") || desc.contains("video tab")
        if (isReelsLabel && isNodeOrParentSelected(node)) return true
        for (i in 0 until node.childCount) {
            if (findReelsTabByDescription(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findReelsNavItemSelected(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 10) return false
        val cls = node.className?.toString()?.lowercase(Locale.US) ?: ""
        if ((cls.contains("tabwidget") || cls.contains("bottom") || cls.contains("navigation")) &&
            node.childCount in 4..6
        ) {
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                val childDesc = child.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
                val isReelsItem = childDesc.contains("reels") || childDesc.contains("reel,") ||
                    childDesc == "reel"
                if (isReelsItem && isNodeOrParentSelected(child)) return true
            }
        }
        for (i in 0 until node.childCount) {
            if (findReelsNavItemSelected(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun hasReelsPlayerIndicators(root: AccessibilityNodeInfo): Boolean {
        if (findReelsOnlyScreen(root)) return true
        val actions = countSideActions(root)
        if (actions >= 2 && findVerticalScrollable(root)) return true
        if (actions >= 2 && findReelsAudioLabel(root)) return true
        return actions >= 3
    }

    private fun findReelsOnlyScreen(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 18) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        if (desc.contains("reel by ") || desc.contains("reels by ")) return true
        if (desc.contains("original audio")) return true
        for (i in 0 until node.childCount) {
            if (findReelsOnlyScreen(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun findReelsAudioLabel(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 18) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        if (desc.contains("original audio") || text.contains("original audio")) return true
        for (i in 0 until node.childCount) {
            if (findReelsAudioLabel(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun collectSideActions(
        node: AccessibilityNodeInfo?,
        found: MutableSet<String>,
        depth: Int,
    ) {
        if (node == null || depth > 24 || found.size >= 5) return
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        val label = when {
            desc.isNotBlank() -> desc
            text.isNotBlank() -> text
            else -> ""
        }
        when {
            label.contains("like") || label.contains("unlike") ||
                label.contains("double tap") -> found.add("like")
            label.contains("comment") -> found.add("comment")
            label.contains("share") || label.contains("send") -> found.add("share")
            label.contains("repost") || label.contains("remix") -> found.add("repost")
            label.contains("save") && !label.contains("saved") -> found.add("save")
            label.contains("original audio") -> found.add("audio")
            label.contains("reel by ") || label.contains("reels by ") -> found.add("reelmeta")
        }
        for (i in 0 until node.childCount) {
            collectSideActions(node.getChild(i), found, depth + 1)
        }
    }

    private fun isNodeOrParentSelected(node: AccessibilityNodeInfo?): Boolean {
        var current = node
        var levels = 0
        while (current != null && levels < 6) {
            val desc = current.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
            if (current.isSelected || current.isChecked || current.isFocused ||
                current.isAccessibilityFocused ||
                desc.contains("selected") || desc.contains("current")
            ) {
                return true
            }
            current = current.parent
            levels++
        }
        return false
    }
}
