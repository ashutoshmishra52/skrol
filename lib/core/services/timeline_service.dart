import 'package:usage_stats/usage_stats.dart';
import '../constants/app_packages.dart';

class TimelineEntry {
  const TimelineEntry({
    required this.time,
    required this.appName,
    required this.packageName,
    required this.durationMinutes,
  });

  final DateTime time;
  final String appName;
  final String packageName;
  final int durationMinutes;

  String get formattedTime {
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
}

class AppOpenStat {
  const AppOpenStat({
    required this.appName,
    required this.packageName,
    required this.minutes,
    required this.openCount,
  });

  final String appName;
  final String packageName;
  final int minutes;
  final int openCount;
}

class TimelineService {
  Future<List<TimelineEntry>> buildTodayTimeline() async {
    try {
      final granted = await UsageStats.checkUsagePermission() ?? false;
      if (!granted) return [];

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final events = await UsageStats.queryEvents(start, end);
      if (events.isEmpty) return [];

      events.sort((a, b) {
        final ta = int.tryParse(a.timeStamp ?? '0') ?? 0;
        final tb = int.tryParse(b.timeStamp ?? '0') ?? 0;
        return ta.compareTo(tb);
      });

      final entries = <TimelineEntry>[];
      String? currentPkg;
      int? sessionStartMs;

      for (final event in events) {
        final pkg = event.packageName ?? '';
        if (!AppPackages.isSocialApp(pkg)) continue;

        final ts = int.tryParse(event.timeStamp ?? '0') ?? 0;
        final isForeground = event.eventType == '1' ||
            event.eventType == 'MOVE_TO_FOREGROUND';
        final isBackground = event.eventType == '2' ||
            event.eventType == 'MOVE_TO_BACKGROUND';

        if (isForeground) {
          if (currentPkg != null && sessionStartMs != null && currentPkg != pkg) {
            _addSession(entries, currentPkg, sessionStartMs, ts);
          }
          currentPkg = pkg;
          sessionStartMs = ts;
        } else if (isBackground && currentPkg == pkg && sessionStartMs != null && currentPkg != null) {
          _addSession(entries, currentPkg!, sessionStartMs, ts);
          currentPkg = null;
          sessionStartMs = null;
        }
      }

      if (currentPkg != null && sessionStartMs != null) {
        _addSession(entries, currentPkg, sessionStartMs, now.millisecondsSinceEpoch);
      }

      entries.sort((a, b) => b.time.compareTo(a.time));
      return entries.take(12).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AppOpenStat>> buildTodayAppOpens() async {
    try {
      final granted = await UsageStats.checkUsagePermission() ?? false;
      if (!granted) return [];

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final events = await UsageStats.queryEvents(start, end);

      final openCounts = <String, int>{};
      for (final event in events) {
        final pkg = event.packageName ?? '';
        if (!AppPackages.isSocialApp(pkg)) continue;
        if (event.eventType == '1' || event.eventType == 'MOVE_TO_FOREGROUND') {
          openCounts[pkg] = (openCounts[pkg] ?? 0) + 1;
        }
      }

      final usage = await UsageStats.queryUsageStats(start, end);
      final minutes = <String, int>{};
      for (final u in usage) {
        final pkg = u.packageName ?? '';
        if (!AppPackages.isSocialApp(pkg)) continue;
        final ms = int.tryParse(u.totalTimeInForeground ?? '0') ?? 0;
        minutes[pkg] = (ms / 60000).round();
      }

      return openCounts.entries.map((e) {
        return AppOpenStat(
          appName: AppPackages.displayName(e.key),
          packageName: e.key,
          minutes: minutes[e.key] ?? 0,
          openCount: e.value,
        );
      }).toList()
        ..sort((a, b) => b.minutes.compareTo(a.minutes));
    } catch (_) {
      return [];
    }
  }

  void _addSession(
    List<TimelineEntry> entries,
    String pkg,
    int startMs,
    int endMs,
  ) {
    final durationMin = ((endMs - startMs) / 60000).round();
    if (durationMin < 2) return;
    entries.add(TimelineEntry(
      time: DateTime.fromMillisecondsSinceEpoch(startMs),
      appName: AppPackages.displayName(pkg),
      packageName: pkg,
      durationMinutes: durationMin,
    ));
  }
}
