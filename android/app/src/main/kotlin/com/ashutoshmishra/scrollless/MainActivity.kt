package com.ashutoshmishra.scrollless

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.ashutoshmishra.scrollless/platform"
    private val feedStatsEventChannel = "com.ashutoshmishra.scrollless/feed_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, feedStatsEventChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    FeedStatsEventBridge.setSink(events)
                    FeedStatsEventBridge.notifyStatsChanged(applicationContext)
                }

                override fun onCancel(arguments: Any?) {
                    FeedStatsEventBridge.setSink(null)
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUsageAccessSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                        } catch (_: Exception) {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        }
                        result.success(null)
                    }
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "getAppLabel" -> {
                        val pkg = call.argument<String>("packageName")
                        if (pkg.isNullOrEmpty()) {
                            result.success(null)
                        } else {
                            result.success(getAppLabel(pkg))
                        }
                    }
                    "getAppLabels" -> {
                        @Suppress("UNCHECKED_CAST")
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val labels = HashMap<String, String>()
                        for (pkg in packages) {
                            labels[pkg] = getAppLabel(pkg)
                        }
                        result.success(labels)
                    }
                    "startReelMonitor", "stopReelMonitor" -> {
                        result.success(null)
                    }
                    "getTrackerStats" -> {
                        AppSwitchTracker.ensureInitialized(this)
                        ReelSessionManager.init(applicationContext)
                        result.success(
                            mapOf(
                                "appSwitches" to AppSwitchTracker.getSwitchCount(this),
                                "reels" to AppSwitchTracker.getReelsCount(this),
                                "shorts" to AppSwitchTracker.getShortsCount(this),
                                "reelsAvgSeconds" to AppSwitchTracker.getReelsAvgSeconds(this),
                                "shortsAvgSeconds" to AppSwitchTracker.getShortsAvgSeconds(this),
                                "reelsWatchMs" to AppSwitchTracker.getReelsWatchMs(this),
                                "shortsWatchMs" to AppSwitchTracker.getShortsWatchMs(this),
                                "hourlyScrollCounts" to AppSwitchTracker.getHourlyScrollCounts(this),
                                "hourlyScrollLabels" to AppSwitchTracker.getHourlyScrollLabels(this),
                            ),
                        )
                    }
                    "getDetectionDebug" -> {
                        result.success(
                            com.ashutoshmishra.scrollless.detection.HybridDebugStore.toMap(),
                        )
                    }
                    "canDrawOverlay" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }
                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(intent)
                        result.success(null)
                    }
                    "computeTodayUsage" -> {
                        if (!PlatformUtils.hasUsagePermission(this)) {
                            result.success(emptyList<Map<String, Any>>())
                        } else {
                            val usage = UsageCalculator.computeTodayUsage(this)
                            result.success(
                                usage.map {
                                    mapOf(
                                        "packageName" to it.packageName,
                                        "appName" to it.label,
                                        "minutes" to it.minutes,
                                        "category" to it.category,
                                    )
                                },
                            )
                        }
                    }
                    "getSocialMediaBreakdown" -> {
                        if (!PlatformUtils.hasUsagePermission(this)) {
                            result.success(emptyMap<String, Any>())
                        } else {
                            val b = UsageCalculator.computeSocialBreakdown(this)
                            result.success(
                                mapOf(
                                    "instagram" to b.instagramMinutes,
                                    "youtube" to b.youtubeMinutes,
                                    "facebook" to b.facebookMinutes,
                                    "x" to b.xMinutes,
                                    "snapchat" to b.snapchatMinutes,
                                    "other" to b.otherMinutes,
                                    "total" to b.totalMinutes,
                                ),
                            )
                        }
                    }
                    "getScrollHistory" -> {
                        AppSwitchTracker.ensureInitialized(this)
                        val days = call.argument<Int>("days") ?: 7
                        result.success(AppSwitchTracker.getScrollHistory(this, days))
                    }
                    "isAccessibilityEnabled" -> {
                        result.success(PlatformUtils.isAccessibilityEnabled(this))
                    }
                    "isBatteryOptimizationIgnored" -> {
                        result.success(isBatteryOptimizationIgnored())
                    }
                    "requestBatteryOptimization" -> {
                        requestIgnoreBatteryOptimization()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getAppLabel(packageName: String): String {
        return try {
            val pm: PackageManager = applicationContext.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            packageName.substringAfterLast('.').replaceFirstChar { it.uppercase() }
        }
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun requestIgnoreBatteryOptimization() {
        if (isBatteryOptimizationIgnored()) return
        try {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
        } catch (_: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }
}
