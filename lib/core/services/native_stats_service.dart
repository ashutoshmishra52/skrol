import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../data/models/app_usage.dart';

class FeedStats {
  const FeedStats({
    this.reelsCount = 0,
    this.shortsCount = 0,
    this.reelsAvgSeconds = 0,
    this.shortsAvgSeconds = 0,
    this.reelsWatchMs = 0,
    this.shortsWatchMs = 0,
    this.hourlyScrollCounts = const [],
    this.hourlyScrollLabels = const [],
  });

  final int reelsCount;
  final int shortsCount;
  final int reelsAvgSeconds;
  final int shortsAvgSeconds;
  final int reelsWatchMs;
  final int shortsWatchMs;
  final List<int> hourlyScrollCounts;
  final List<String> hourlyScrollLabels;

  int get totalCount => reelsCount + shortsCount;
  int get totalWatchMs => reelsWatchMs + shortsWatchMs;

  static const empty = FeedStats();

  FeedStats copyWith({
    int? reelsCount,
    int? shortsCount,
    int? reelsAvgSeconds,
    int? shortsAvgSeconds,
    int? reelsWatchMs,
    int? shortsWatchMs,
    List<int>? hourlyScrollCounts,
    List<String>? hourlyScrollLabels,
  }) {
    return FeedStats(
      reelsCount: reelsCount ?? this.reelsCount,
      shortsCount: shortsCount ?? this.shortsCount,
      reelsAvgSeconds: reelsAvgSeconds ?? this.reelsAvgSeconds,
      shortsAvgSeconds: shortsAvgSeconds ?? this.shortsAvgSeconds,
      reelsWatchMs: reelsWatchMs ?? this.reelsWatchMs,
      shortsWatchMs: shortsWatchMs ?? this.shortsWatchMs,
      hourlyScrollCounts: hourlyScrollCounts ?? this.hourlyScrollCounts,
      hourlyScrollLabels: hourlyScrollLabels ?? this.hourlyScrollLabels,
    );
  }

  factory FeedStats.fromMap(Map<Object?, Object?> map) {
    return FeedStats(
      reelsCount: (map['reels'] as num?)?.toInt() ?? 0,
      shortsCount: (map['shorts'] as num?)?.toInt() ?? 0,
      reelsAvgSeconds: (map['reelsAvgSeconds'] as num?)?.toInt() ?? 0,
      shortsAvgSeconds: (map['shortsAvgSeconds'] as num?)?.toInt() ?? 0,
      reelsWatchMs: (map['reelsWatchMs'] as num?)?.toInt() ?? 0,
      shortsWatchMs: (map['shortsWatchMs'] as num?)?.toInt() ?? 0,
      hourlyScrollCounts: _parseIntList(map['hourlyScrollCounts']),
      hourlyScrollLabels: _parseStringList(map['hourlyScrollLabels']),
    );
  }

  static List<int> _parseIntList(Object? value) {
    if (value is! List) return const [];
    return value.map((e) => (e as num?)?.toInt() ?? 0).toList();
  }

  static List<String> _parseStringList(Object? value) {
    if (value is! List) return const [];
    return value.map((e) => e?.toString() ?? '').toList();
  }
}

class NativeStatsService {
  static const _channel = MethodChannel('com.ashutoshmishra.scrollless/platform');
  static const _feedStatsEvents =
      EventChannel('com.ashutoshmishra.scrollless/feed_stats');

  static Stream<FeedStats>? _feedStatsStream;

  /// Real-time feed stats: EventChannel push + 3s polling fallback.
  static Stream<FeedStats> get feedStatsStream {
    _feedStatsStream ??= _createFeedStatsStream();
    return _feedStatsStream!;
  }

  static Stream<FeedStats> _createFeedStatsStream() {
    return Stream.multi((controller) async {
      controller.add(await getFeedStats());

      final eventSub = _feedStatsEvents.receiveBroadcastStream().listen(
        (event) {
          if (event is Map) {
            controller.add(FeedStats.fromMap(event));
          }
        },
        onError: (Object e) => debugPrint('Feed stats event error: $e'),
      );

      final pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        controller.add(await getFeedStats());
      });

      controller.onCancel = () {
        eventSub.cancel();
        pollTimer.cancel();
      };
    });
  }

  static Future<int> getAppSwitchCount() async {
    try {
      final stats = await getTrackerStats();
      return stats.appSwitches;
    } catch (e) {
      debugPrint('App switch count failed: $e');
      return 0;
    }
  }

  static Future<FeedStats> getFeedStats() async {
    try {
      final stats = await getTrackerStats();
      return FeedStats(
        reelsCount: stats.reels,
        shortsCount: stats.shorts,
        reelsAvgSeconds: stats.reelsAvgSeconds,
        shortsAvgSeconds: stats.shortsAvgSeconds,
        reelsWatchMs: stats.reelsWatchMs,
        shortsWatchMs: stats.shortsWatchMs,
        hourlyScrollCounts: stats.hourlyScrollCounts,
        hourlyScrollLabels: stats.hourlyScrollLabels,
      );
    } catch (e) {
      debugPrint('Feed stats failed: $e');
      return FeedStats.empty;
    }
  }

  static Future<({
    int appSwitches,
    int reels,
    int shorts,
    int reelsAvgSeconds,
    int shortsAvgSeconds,
    int reelsWatchMs,
    int shortsWatchMs,
    List<int> hourlyScrollCounts,
    List<String> hourlyScrollLabels,
  })> getTrackerStats() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getTrackerStats');
      if (result == null) {
        return (
          appSwitches: 0,
          reels: 0,
          shorts: 0,
          reelsAvgSeconds: 0,
          shortsAvgSeconds: 0,
          reelsWatchMs: 0,
          shortsWatchMs: 0,
          hourlyScrollCounts: <int>[],
          hourlyScrollLabels: <String>[],
        );
      }
      return (
        appSwitches: (result['appSwitches'] as num?)?.toInt() ?? 0,
        reels: (result['reels'] as num?)?.toInt() ?? 0,
        shorts: (result['shorts'] as num?)?.toInt() ?? 0,
        reelsAvgSeconds: (result['reelsAvgSeconds'] as num?)?.toInt() ?? 0,
        shortsAvgSeconds: (result['shortsAvgSeconds'] as num?)?.toInt() ?? 0,
        reelsWatchMs: (result['reelsWatchMs'] as num?)?.toInt() ?? 0,
        shortsWatchMs: (result['shortsWatchMs'] as num?)?.toInt() ?? 0,
        hourlyScrollCounts: FeedStats._parseIntList(result['hourlyScrollCounts']),
        hourlyScrollLabels: FeedStats._parseStringList(result['hourlyScrollLabels']),
      );
    } catch (e) {
      debugPrint('Tracker stats failed: $e');
      return (
        appSwitches: 0,
        reels: 0,
        shorts: 0,
        reelsAvgSeconds: 0,
        shortsAvgSeconds: 0,
        reelsWatchMs: 0,
        shortsWatchMs: 0,
        hourlyScrollCounts: <int>[],
        hourlyScrollLabels: <String>[],
      );
    }
  }

  static Future<void> stopReelMonitor() async {
    try {
      await _channel.invokeMethod('stopReelMonitor');
    } catch (_) {}
  }

  static Future<bool> canDrawOverlay() async {
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlay') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Overlay permission failed: $e');
    }
  }

  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<SocialMediaBreakdown> getSocialMediaBreakdown() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getSocialMediaBreakdown');
      if (result == null) return SocialMediaBreakdown.empty;
      return SocialMediaBreakdown.fromMap(result);
    } catch (e) {
      debugPrint('Social breakdown failed: $e');
      return SocialMediaBreakdown.empty;
    }
  }

  static Future<List<DailyScrollRecord>> getScrollHistory({int days = 7}) async {
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

  static Future<Map<String, dynamic>> getDetectionDebug() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getDetectionDebug');
      if (result == null) return {};
      return result.map((k, v) => MapEntry(k.toString(), v));
    } catch (e) {
      debugPrint('Detection debug failed: $e');
      return {};
    }
  }
}
