package com.ashutoshmishra.scrollless

import android.accessibilityservice.AccessibilityService
import android.os.Build
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import com.ashutoshmishra.scrollless.detection.FeedSessionDetector
import java.util.Locale

object TabDetector {
    const val PKG_INSTAGRAM = "com.instagram.android"
    const val PKG_YOUTUBE = "com.google.android.youtube"

    enum class FeedMode { NONE, REELS, SHORTS }

    fun detectMode(service: AccessibilityService): FeedMode {
        val root = getActiveRoot(service) ?: return FeedMode.NONE
        val pkg = root.packageName?.toString() ?: return FeedMode.NONE
        return when (pkg) {
            PKG_INSTAGRAM -> if (FeedSessionDetector.isReelsActive(root)) FeedMode.REELS else FeedMode.NONE
            PKG_YOUTUBE -> if (FeedSessionDetector.isShortsActive(root)) FeedMode.SHORTS else FeedMode.NONE
            else -> FeedMode.NONE
        }
    }

    fun getActiveRoot(service: AccessibilityService): AccessibilityNodeInfo? {
        val direct = service.rootInActiveWindow
        if (direct != null) return direct
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val windows = service.windows ?: return null
            for (window in windows) {
                if (window.type == AccessibilityWindowInfo.TYPE_APPLICATION) {
                    val root = window.root ?: continue
                    if (root.packageName?.toString() == PKG_INSTAGRAM ||
                        root.packageName?.toString() == PKG_YOUTUBE
                    ) {
                        return root
                    }
                }
            }
            for (window in windows) {
                window.root?.let { return it }
            }
        }
        return null
    }

    fun isInstagramReelsContext(service: AccessibilityService): Boolean {
        val root = getActiveRoot(service) ?: return false
        if (root.packageName?.toString() != PKG_INSTAGRAM) return false
        return isInstagramReelsRoot(root)
    }

    fun isInstagramReelsTabSelected(service: AccessibilityService): Boolean {
        return isInstagramReelsContext(service)
    }

    fun isInstagramHomeTabSelected(service: AccessibilityService): Boolean {
        val root = getActiveRoot(service) ?: return false
        if (root.packageName?.toString() != PKG_INSTAGRAM) return false
        return isHomeTabExplicitlySelected(root)
    }

    fun isInstagramHomeOrFeedContext(service: AccessibilityService): Boolean {
        return isInstagramHomeTabSelected(service)
    }

    fun isYoutubeShortsContext(service: AccessibilityService): Boolean {
        val root = getActiveRoot(service) ?: return false
        if (root.packageName?.toString() != PKG_YOUTUBE) return false
        return isYoutubeShortsRoot(root)
    }

    fun isYoutubeShortsTabSelected(service: AccessibilityService): Boolean {
        val root = getActiveRoot(service) ?: return false
        if (root.packageName?.toString() != PKG_YOUTUBE) return false
        return findSelectedTab(root, "shorts")
    }

    fun isYoutubeHomeOrWatchContext(service: AccessibilityService): Boolean {
        val root = getActiveRoot(service) ?: return false
        if (root.packageName?.toString() != PKG_YOUTUBE) return false
        return isYoutubeHomeOrWatchRoot(root)
    }

    fun shortsPageSignature(service: AccessibilityService): String? {
        return pageSignature(getActiveRoot(service), includeReels = false)
    }

    fun reelsPageSignature(service: AccessibilityService): String? {
        return pageSignature(getActiveRoot(service), includeReels = true)
    }

    private fun pageSignature(root: AccessibilityNodeInfo?, includeReels: Boolean): String? {
        if (root == null) return null
        val sb = StringBuilder()
        collectSignatureText(root, sb, 0, includeReels)
        val s = sb.toString().trim()
        return if (s.length >= 4) s.hashCode().toString() else null
    }

    private fun collectSignatureText(
        node: AccessibilityNodeInfo?,
        sb: StringBuilder,
        depth: Int,
        includeReels: Boolean,
    ) {
        if (node == null || depth > 18 || sb.length > 500) return
        val desc = node.contentDescription?.toString()?.trim() ?: ""
        val text = node.text?.toString()?.trim() ?: ""
        if (desc.length in 4..150 && !isGenericUiLabel(desc, includeReels)) {
            sb.append(desc).append('|')
        }
        if (text.length in 3..100 && !isGenericUiLabel(text, includeReels)) {
            sb.append(text).append('|')
        }
        val viewId = node.viewIdResourceName?.lowercase(Locale.US) ?: ""
        if (viewId.contains("reel") || viewId.contains("clips")) {
            sb.append(viewId).append('|')
        }
        for (i in 0 until node.childCount) {
            collectSignatureText(node.getChild(i), sb, depth + 1, includeReels)
        }
    }

    private fun isGenericUiLabel(s: String, includeReels: Boolean): Boolean {
        val lower = s.lowercase(Locale.US)
        if (lower == "shorts" || lower == "home" || lower == "search" ||
            lower == "subscriptions" || lower == "library" || lower == "you" ||
            lower == "reels" || lower == "explore" || lower == "profile"
        ) {
            return true
        }
        return lower.contains("tab ") && lower.length < 24
    }

    private fun isInstagramReelsRoot(root: AccessibilityNodeInfo): Boolean {
        return FeedSessionDetector.isReelsActive(root)
    }

    private fun isYoutubeShortsRoot(root: AccessibilityNodeInfo): Boolean {
        return FeedSessionDetector.isShortsActive(root)
    }

    private fun isBlockingInstagramTabSelected(root: AccessibilityNodeInfo): Boolean {
        return isHomeTabExplicitlySelected(root) ||
            findSelectedTab(root, "profile") ||
            findSelectedTab(root, "search") ||
            findSelectedTab(root, "explore") ||
            findSelectedTab(root, "create")
    }

    private fun isHomeTabExplicitlySelected(root: AccessibilityNodeInfo): Boolean {
        if (findSelectedTab(root, "home")) return true
        if (findHomeFeedFragment(root) && !hasReelsPlayerIndicators(root)) return true
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
        if (cls.contains("clips") && (cls.contains("viewer") || cls.contains("fragment"))) {
            return true
        }
        for (i in 0 until node.childCount) {
            if (findReelsFragment(node.getChild(i), depth + 1)) return true
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

    private fun isReelsTabActive(root: AccessibilityNodeInfo): Boolean {
        if (findSelectedTab(root, "reels")) return true
        if (findReelsTabByDescription(root)) return true
        if (findReelsNavItemSelected(root)) return true
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

    /** Bottom nav: Reels is often 2nd of 5 tabs — detect selected position. */
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

    private fun hasReelsPlayerIndicators(root: AccessibilityNodeInfo): Boolean {
        if (findReelsOnlyScreen(root)) return true
        val actions = countSideActions(root)
        if (actions >= 2 && findVerticalScrollable(root)) return true
        if (actions >= 2 && findReelsAudioLabel(root)) return true
        if (actions >= 3) return true
        return false
    }

    private fun countSideActions(node: AccessibilityNodeInfo?, depth: Int = 0): Int {
        val found = mutableSetOf<String>()
        collectSideActionLabels(node, found, 0)
        return found.size
    }

    private fun collectSideActionLabels(
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
            label.contains("audio") && label.length < 40 -> found.add("audio")
        }
        for (i in 0 until node.childCount) {
            collectSideActionLabels(node.getChild(i), found, depth + 1)
        }
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

    private fun isYoutubeHomeOrWatchRoot(root: AccessibilityNodeInfo): Boolean {
        if (findSelectedTab(root, "shorts")) return false
        if (findSelectedTab(root, "home")) return true
        if (findSelectedTab(root, "subscriptions")) return true
        if (findSelectedTab(root, "library")) return true
        if (findSelectedTab(root, "explore")) return true
        if (findLongFormWatchPlayer(root)) return true
        return false
    }

    private fun findShortsResourceIds(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val viewId = node.viewIdResourceName?.lowercase(Locale.US) ?: ""
        if (viewId.contains("shorts") &&
            (viewId.contains("tab") || viewId.contains("player") || viewId.contains("fragment"))
        ) {
            return true
        }
        for (i in 0 until node.childCount) {
            if (findShortsResourceIds(node.getChild(i), depth + 1)) return true
        }
        return false
    }

    private fun countShortsSideActions(root: AccessibilityNodeInfo): Int {
        val found = mutableSetOf<String>()
        collectSideActionLabels(root, found, 0)
        return found.size
    }

    private fun findShortsSoundOrChannel(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        if (desc.contains("sound") || desc.contains("remix")) return true
        if (text.contains("@") && text.length < 40) return true
        for (i in 0 until node.childCount) {
            if (findShortsSoundOrChannel(node.getChild(i), depth + 1)) return true
        }
        return false
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

    private fun hasVisibleTab(node: AccessibilityNodeInfo?, tabName: String, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val text = node.text?.toString()?.lowercase(Locale.US) ?: ""
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        if (text == tabName || desc.contains(tabName)) return true
        for (i in 0 until node.childCount) {
            if (hasVisibleTab(node.getChild(i), tabName, depth + 1)) return true
        }
        return false
    }

    private fun findDefiniteShortsOnlyUI(node: AccessibilityNodeInfo?, depth: Int = 0): Boolean {
        if (node == null || depth > 16) return false
        val desc = node.contentDescription?.toString()?.lowercase(Locale.US) ?: ""
        val cls = node.className?.toString()?.lowercase(Locale.US) ?: ""
        if (desc.contains("remix") && desc.contains("short")) return true
        if (desc.contains("create a short")) return true
        if (cls.contains("shorts") && (cls.contains("player") || cls.contains("fragment"))) return true
        for (i in 0 until node.childCount) {
            if (findDefiniteShortsOnlyUI(node.getChild(i), depth + 1)) return true
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
        if (combined.contains("full screen") && combined.contains("player")) return true
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
}
