package com.ashutoshmishra.scrollless

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

class ReelOverlayManager(private val context: Context) {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var container: LinearLayout? = null
    private var countText: TextView? = null

    fun canDrawOverlay(): Boolean = Settings.canDrawOverlays(context)

    fun update(count: Int) {
        if (!canDrawOverlay()) return
        ensureView()

        countText?.text = count.toString()
        applyBackgroundColor(count)
        overlayView?.visibility = View.VISIBLE
    }

    fun hide() {
        overlayView?.visibility = View.GONE
    }

    private fun backgroundColorForCount(count: Int): Int = when {
        count >= 100 -> Color.parseColor("#D9EF4444")
        count >= 51 -> Color.parseColor("#D9EAB308")
        else -> Color.parseColor("#D922C55E")
    }

    private fun applyBackgroundColor(count: Int) {
        val bg = container?.background as? GradientDrawable ?: return
        bg.setColor(backgroundColorForCount(count))
    }

    private fun statusBarHeight(): Int {
        val resId = context.resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resId > 0) context.resources.getDimensionPixelSize(resId) else {
            TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP,
                28f,
                context.resources.displayMetrics,
            ).toInt()
        }
    }

    private fun ensureView() {
        if (overlayView != null) return
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        overlayView = LayoutInflater.from(context).inflate(R.layout.reel_overlay, null)
        container = overlayView as? LinearLayout
        countText = overlayView?.findViewById(R.id.count_text)

        val cornerPx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            8f,
            context.resources.displayMetrics,
        )
        val bg = GradientDrawable().apply {
            cornerRadius = cornerPx
            setColor(backgroundColorForCount(0))
        }
        container?.background = bg

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 6
            y = statusBarHeight() + 4
        }

        windowManager?.addView(overlayView, params)
        overlayView?.visibility = View.GONE
    }

    fun destroy() {
        overlayView?.let { windowManager?.removeView(it) }
        overlayView = null
        container = null
        countText = null
    }
}
