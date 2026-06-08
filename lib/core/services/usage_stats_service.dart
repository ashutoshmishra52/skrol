import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import '../../core/constants/app_packages.dart';
import '../../data/models/app_usage.dart';
import '../../data/repositories/repositories.dart';

class UsageStatsService {
  UsageStatsService();

  static const _channel = MethodChannel('com.ashutoshmishra.scrollless/platform');

  final UsageRepository _usageRepo = UsageRepository();

  Future<bool> hasPermission() async {
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Accurate today sync via native UsageStatsManager event pairing.
  Future<void> syncUsageData({int days = 1}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await _usageRepo.clearUsageForDate(today);

      final nativeUsage = await _fetchNativeTodayUsage();
      for (final item in nativeUsage) {
        final packageName = item['packageName'] as String? ?? '';
        final minutes = item['minutes'] as int? ?? 0;
        if (packageName.isEmpty || minutes <= 0) continue;
        if (!AppPackages.socialMediaApps.contains(packageName)) continue;

        await _usageRepo.saveUsageRecord(AppUsageRecord(
          packageName: packageName,
          appName: AppPackages.displayName(packageName),
          date: today,
          usageMinutes: minutes,
          category: 'Social',
          isDistraction: true,
        ));
      }
    } catch (e) {
      debugPrint('Usage sync failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNativeTodayUsage() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('computeTodayUsage');
      if (result == null) return [];
      return result.map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{};
      }).where((m) => m.isNotEmpty).toList();
    } catch (e) {
      debugPrint('Native usage fetch failed: $e');
      return [];
    }
  }

  Future<SocialMediaBreakdown> fetchSocialBreakdown() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getSocialMediaBreakdown');
      if (result == null) return SocialMediaBreakdown.empty;
      return SocialMediaBreakdown.fromMap(result);
    } catch (e) {
      debugPrint('Social breakdown failed: $e');
      return SocialMediaBreakdown.empty;
    }
  }

  Future<List<DailyScrollRecord>> fetchScrollHistory({int days = 7}) async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'getScrollHistory',
        {'days': days},
      );
      if (result == null) return [];
      return result
          .whereType<Map>()
          .map((m) => DailyScrollRecord.fromMap(m))
          .toList();
    } catch (e) {
      debugPrint('Scroll history failed: $e');
      return [];
    }
  }

  Future<List<AppUsageRecord>> getTodayUsage() async {
    await syncUsageData(days: 1);
    return _usageRepo.getUsageForDate(DateTime.now());
  }
}
