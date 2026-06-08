package com.ashutoshmishra.scrollless

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import com.ashutoshmishra.scrollless.detection.HybridDetectionEngine
import com.ashutoshmishra.scrollless.detection.NodeTreeDumper

class ScrollLessAccessibilityService : AccessibilityService() {

    private var lastForegroundPkg: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        ReelSessionManager.init(this)
        AppSwitchTracker.ensureInitialized(this)
        HybridDetectionEngine.onServiceConnected(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                trackAppSwitch(pkg)
            }
        }

        if (pkg == TabDetector.PKG_INSTAGRAM || pkg == TabDetector.PKG_YOUTUBE) {
            HybridDetectionEngine.onAnyEvent(this, event)
        }

        // Debug tree capture runs after counting — never blocks count path
        if (pkg == TabDetector.PKG_INSTAGRAM) {
            NodeTreeDumper.captureOnInstagramEvent(this, event)
        }
    }

    private fun trackAppSwitch(pkg: String) {
        if (pkg == packageName) return
        if (pkg == lastForegroundPkg) return
        lastForegroundPkg = pkg

        if (pkg != TabDetector.PKG_INSTAGRAM && pkg != TabDetector.PKG_YOUTUBE) {
            HybridDetectionEngine.onAppBackgrounded()
        }

        AppSwitchTracker.onAppForeground(this, pkg)
    }

    override fun onInterrupt() {}
}
