package com.ashutoshmishra.scrollless.detection

import android.graphics.Rect
import android.view.accessibility.AccessibilityNodeInfo
import java.util.Locale
import java.util.regex.Pattern

/**
 * Builds fingerprints from the accessibility tree.
 * Instagram Reels uses a stable subset to avoid like-count / UI noise.
 */
object NodeHashGenerator {

    private val genericLabels = setOf(
        "like", "unlike", "comment", "share", "save", "follow", "following",
        "home", "search", "reels", "shorts", "profile", "more", "menu",
        "back", "close", "play", "pause", "mute", "unmute", "audio",
        "double tap", "send", "repost", "remix",
    )

    private val volatilePattern = Pattern.compile(
        """^\d[\d,.]*[km]?$|^\d+\s*(likes?|views?|comments?|shares?)$|^\d+:\d+$|^\d+\s*(sec|min|hour|day|week|month|year)s?\s*ago$""",
        Pattern.CASE_INSENSITIVE,
    )

    fun generate(root: AccessibilityNodeInfo?): String {
        if (root == null) return ""
        val sb = StringBuilder(512)
        collect(root, sb, 0, stableOnly = false)
        return finalizeHash(sb)
    }

    /** Stable hash for Instagram Reels — ignores volatile like counts and timers. */
    fun generateForReels(root: AccessibilityNodeInfo?): String {
        if (root == null) return ""
        val sb = StringBuilder(512)
        collectReelsStable(root, sb, 0)
        return finalizeHash(sb)
    }

    fun preview(root: AccessibilityNodeInfo?): String {
        if (root == null) return ""
        val sb = StringBuilder(120)
        collectPreview(root, sb, 0)
        return sb.toString().take(100)
    }

    private fun finalizeHash(sb: StringBuilder): String {
        val raw = sb.toString().trim()
        if (raw.length < 6) return ""
        return raw.hashCode().toUInt().toString(16)
    }

    private fun collectReelsStable(node: AccessibilityNodeInfo?, sb: StringBuilder, depth: Int) {
        if (node == null || depth > 18 || sb.length > 4000) return

        val viewId = node.viewIdResourceName?.lowercase(Locale.US) ?: ""
        if (viewId.contains("clips") || viewId.contains("reel") ||
            viewId.contains("viewer") || viewId.contains("video")
        ) {
            sb.append("id:").append(viewId.substringAfterLast('/')).append(';')
        }

        val desc = node.contentDescription?.toString()?.trim() ?: ""
        val text = node.text?.toString()?.trim() ?: ""

        if (desc.lowercase(Locale.US).contains("reel by ")) {
            sb.append("rb:").append(normalizeCreator(desc)).append(';')
        }
        if (isCreatorHandle(text)) {
            sb.append("cr:").append(text.lowercase(Locale.US)).append(';')
        }
        if (isStableCaption(text)) {
            sb.append("cp:").append(text.lowercase(Locale.US).take(60)).append(';')
        }
        if (desc.lowercase(Locale.US).contains("original audio")) {
            sb.append("aud:").append(normalizeCreator(desc)).append(';')
        }

        for (i in 0 until node.childCount) {
            collectReelsStable(node.getChild(i), sb, depth + 1)
        }
    }

    private fun collect(
        node: AccessibilityNodeInfo?,
        sb: StringBuilder,
        depth: Int,
        stableOnly: Boolean,
    ) {
        if (node == null || depth > 16 || sb.length > 5000) return

        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        if (bounds.width() < 40 || bounds.height() < 40) {
            skipChildren(node, sb, depth, stableOnly)
            return
        }

        val viewId = node.viewIdResourceName?.substringAfterLast('/') ?: ""
        val desc = sanitize(node.contentDescription?.toString())
        val text = sanitize(node.text?.toString())
        val cls = node.className?.toString()?.substringAfterLast('.')?.lowercase(Locale.US) ?: ""

        if (viewId.isNotBlank()) sb.append("id:").append(viewId).append(';')
        if (desc.isNotBlank()) sb.append("d:").append(desc).append(';')
        if (text.isNotBlank() && text.length in 3..60) sb.append("t:").append(text).append(';')
        if (cls.contains("video") || cls.contains("player") || cls.contains("reel") ||
            cls.contains("short") || cls.contains("viewpager")
        ) {
            sb.append("c:").append(cls).append('@').append(bounds.width())
                .append('x').append(bounds.height()).append(';')
        }

        for (i in 0 until node.childCount) {
            collect(node.getChild(i), sb, depth, stableOnly)
        }
    }

    private fun collectPreview(node: AccessibilityNodeInfo?, sb: StringBuilder, depth: Int) {
        if (node == null || depth > 8 || sb.length > 100) return
        val desc = node.contentDescription?.toString()?.trim() ?: ""
        val text = node.text?.toString()?.trim() ?: ""
        if (desc.length in 5..80 && !isGeneric(desc)) sb.append(desc).append('|')
        if (text.length in 3..40 && !isGeneric(text)) sb.append(text).append('|')
        for (i in 0 until node.childCount) {
            collectPreview(node.getChild(i), sb, depth + 1)
        }
    }

    private fun skipChildren(
        node: AccessibilityNodeInfo?,
        sb: StringBuilder,
        depth: Int,
        stableOnly: Boolean,
    ) {
        if (node == null) return
        for (i in 0 until node.childCount) {
            collect(node.getChild(i), sb, depth + 1, stableOnly)
        }
    }

    private fun normalizeCreator(s: String): String {
        return s.lowercase(Locale.US)
            .replace("reel by ", "")
            .replace("reels by ", "")
            .trim()
            .take(50)
    }

    private fun isCreatorHandle(text: String): Boolean {
        return text.startsWith("@") && text.length in 2..40
    }

    private fun isStableCaption(text: String): Boolean {
        if (text.length < 8 || text.length > 120) return false
        if (text.startsWith("@")) return false
        if (volatilePattern.matcher(text).matches()) return false
        if (text.all { it.isDigit() || it in ".,kKmM " }) return false
        return !isGeneric(text)
    }

    private fun sanitize(raw: String?): String {
        if (raw.isNullOrBlank()) return ""
        val s = raw.trim().lowercase(Locale.US).take(80)
        if (isGeneric(s)) return ""
        if (volatilePattern.matcher(s).matches()) return ""
        return s
    }

    private fun isGeneric(s: String): Boolean {
        val lower = s.lowercase(Locale.US)
        if (lower.length < 3) return true
        return genericLabels.any { lower == it || lower.startsWith("$it ") || lower.contains(" button") }
    }
}
