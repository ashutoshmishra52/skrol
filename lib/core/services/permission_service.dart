import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';
import '../../data/repositories/repositories.dart';
import '../platform/app_platform.dart';

import 'native_stats_service.dart';

class PermissionStatus {
  PermissionStatus({
    required this.usageStatsGranted,
    required this.notificationGranted,
    required this.accessibilityGranted,
    required this.overlayGranted,
  });

  final bool usageStatsGranted;
  final bool notificationGranted;
  final bool accessibilityGranted;
  final bool overlayGranted;

  bool get allRequiredGranted => supportsUsageStats ? usageStatsGranted : true;

  bool get reelCounterReady =>
      supportsReelsTracking && accessibilityGranted && overlayGranted;
}

class PermissionService {
  static const _channel = MethodChannel('com.ashutoshmishra.scrollless/platform');
  final SettingsRepository _settingsRepo = SettingsRepository();

  Future<PermissionStatus> checkAll() async {
    if (isIOSPlatform) {
      final notificationGranted = await Permission.notification.isGranted;
      return PermissionStatus(
        usageStatsGranted: false,
        notificationGranted: notificationGranted,
        accessibilityGranted: false,
        overlayGranted: false,
      );
    }

    final usageGranted = await UsageStats.checkUsagePermission() ?? false;
    final notificationGranted = await Permission.notification.isGranted;
    final accessibilityGranted = await NativeStatsService.isAccessibilityEnabled();
    final overlayGranted = await NativeStatsService.canDrawOverlay();
    final settings = _settingsRepo.getSettings();

    if (usageGranted != settings.usageStatsGranted ||
        notificationGranted != settings.notificationGranted ||
        accessibilityGranted != settings.accessibilityGranted) {
      await _settingsRepo.saveSettings(settings.copyWith(
        usageStatsGranted: usageGranted,
        notificationGranted: notificationGranted,
        accessibilityGranted: accessibilityGranted,
      ));
    }

    return PermissionStatus(
      usageStatsGranted: usageGranted,
      notificationGranted: notificationGranted,
      accessibilityGranted: accessibilityGranted,
      overlayGranted: overlayGranted,
    );
  }

  /// Opens system Usage Access settings. User must tap Allow for SKROL.
  /// Re-check permission when app resumes (Settings → back to app).
  Future<bool> requestUsageStats() async {
    if (!supportsUsageStats) return false;

    final alreadyGranted = await UsageStats.checkUsagePermission() ?? false;
    if (alreadyGranted) {
      await _updateUsageGranted(true);
      return true;
    }

    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (e) {
      debugPrint('Platform usage settings failed: $e');
      try {
        await UsageStats.grantUsagePermission().timeout(
          const Duration(seconds: 2),
          onTimeout: () {},
        );
      } catch (_) {}
    }
    return false;
  }

  Future<bool> recheckUsageStatsAfterSettings() async {
    if (!supportsUsageStats) return false;

    final granted = await UsageStats.checkUsagePermission() ?? false;
    await _updateUsageGranted(granted);
    return granted;
  }

  Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    final granted = status.isGranted;
    await _updateNotificationGranted(granted);
    if (!granted) {
      try {
        await _channel.invokeMethod('openNotificationSettings');
      } catch (_) {}
    }
    return granted;
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      debugPrint('Accessibility settings failed: $e');
      await openAppSettings();
    }
  }

  Future<void> requestOverlayPermission() async {
    await NativeStatsService.requestOverlayPermission();
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      return await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } catch (e) {
      debugPrint('Battery optimization request failed: $e');
    }
  }

  Future<void> markAccessibilityGranted() async {
    final granted = await NativeStatsService.isAccessibilityEnabled();
    final settings = _settingsRepo.getSettings();
    await _settingsRepo.saveSettings(
      settings.copyWith(accessibilityGranted: granted),
    );
  }

  Future<void> _updateUsageGranted(bool granted) async {
    final settings = _settingsRepo.getSettings();
    await _settingsRepo.saveSettings(
      settings.copyWith(usageStatsGranted: granted),
    );
  }

  Future<void> _updateNotificationGranted(bool granted) async {
    final settings = _settingsRepo.getSettings();
    await _settingsRepo.saveSettings(
      settings.copyWith(notificationGranted: granted),
    );
  }
}
