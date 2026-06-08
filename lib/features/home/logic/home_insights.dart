import '../../../core/services/native_stats_service.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../data/models/app_usage.dart';

class HomeInsightsResult {
  const HomeInsightsResult({
    required this.smartInsights,
    required this.behaviorInsights,
    required this.recommendations,
  });

  final List<String> smartInsights;
  final List<String> behaviorInsights;
  final List<String> recommendations;
}

class HomeInsightsBuilder {
  static HomeInsightsResult build({
    required FeedStats feedStats,
    required List<DailyScrollRecord> history,
    required SocialMediaBreakdown social,
    required int focusMinutes,
    required int weeklyScreenChange,
  }) {
    final today = history.isNotEmpty ? history.first : null;
    final yesterday = history.length > 1 ? history[1] : null;
    final twoDaysAgo = history.length > 2 ? history[2] : null;

    final todayReels = today?.reels ?? feedStats.reelsCount;
    final todayShorts = today?.shorts ?? feedStats.shortsCount;
    final yReels = yesterday?.reels ?? 0;
    final yShorts = yesterday?.shorts ?? 0;

    final smart = <String>[];

    if (todayReels > 0) {
      smart.add('You watched $todayReels Reels today.');
    }
    if (yReels > 0) {
      smart.add('Yesterday you watched $yReels Reels.');
      final delta = todayReels - yReels;
      if (delta != 0) {
        final pct = yReels > 0 ? ((delta / yReels) * 100).round().abs() : 0;
        if (delta > 0) {
          smart.add('Your Reels consumption increased by $pct%.');
        } else {
          smart.add('Your Reels consumption dropped by $pct%.');
        }
      }
    }

    if (todayShorts > 0) {
      smart.add(
        'You watched $todayShorts Shorts today${yShorts > 0 ? ' compared to $yShorts yesterday' : ''}.',
      );
    }

    if (twoDaysAgo != null) {
      final twoTotal = twoDaysAgo.totalScrolls;
      final todayTotal = todayReels + todayShorts;
      if (twoTotal > 0 && todayTotal < twoTotal) {
        smart.add('You are scrolling less than 2 days ago.');
      } else if (twoTotal > 0 && todayTotal > twoTotal) {
        smart.add('You are scrolling more than 2 days ago.');
      }
    }

    final peakDay = _peakDay(history);
    if (peakDay != null) {
      smart.add('Your highest scrolling day this week was ${peakDay.label}.');
    }

    final totalScroll = todayReels + todayShorts;
    if (totalScroll > 0) {
      final igShare = ((todayReels / totalScroll) * 100).round();
      smart.add('Instagram accounted for $igShare% of today\'s short-form content.');
    }

    if (social.totalMinutes > 0) {
      smart.add(
        'Total social media time: ${app_date.DateUtils.formatMinutes(social.totalMinutes)}.',
      );
    }

    final behavior = <String>[];
    final peakWindow = _peakTimeWindow(feedStats);
    if (peakWindow != null) {
      behavior.add('Most scrolling occurred between $peakWindow.');
    }

    final longestSession = _longestSessionMinutes(feedStats);
    if (longestSession > 0) {
      behavior.add('Your longest session lasted $longestSession minutes.');
    }

    if (weeklyScreenChange != 0) {
      if (weeklyScreenChange < 0) {
        behavior.add('You reduced screen time by ${weeklyScreenChange.abs()}% this week.');
      } else {
        behavior.add('Screen time increased ${weeklyScreenChange}% this week.');
      }
    }

    final recs = <String>[];
    if (_hasNightSpike(feedStats)) {
      recs.add('Your scrolling spikes at night. Try Focus Mode after 9 PM.');
    }
    if (social.instagramMinutes > social.youtubeMinutes && social.instagramMinutes > 30) {
      recs.add('Instagram used the most time today. Set a Reels limit.');
    }
    if (weeklyScreenChange < 0) {
      recs.add('You are ${weeklyScreenChange.abs()}% better than last week. Keep going.');
    } else if (todayReels + todayShorts > 80) {
      recs.add('High scroll volume today. Plan a screen-free block tomorrow morning.');
    } else {
      recs.add('Small limits tonight can make tomorrow noticeably calmer.');
    }

    return HomeInsightsResult(
      smartInsights: smart.take(6).toList(),
      behaviorInsights: behavior.take(3).toList(),
      recommendations: recs.take(3).toList(),
    );
  }

  static _PeakDay? _peakDay(List<DailyScrollRecord> history) {
    if (history.isEmpty) return null;
    var max = 0;
    var idx = 0;
    for (var i = 0; i < history.length; i++) {
      final total = history[i].totalScrolls;
      if (total > max) {
        max = total;
        idx = i;
      }
    }
    if (max == 0) return null;
    return _PeakDay(_dayLabel(idx), max);
  }

  static String _dayLabel(int daysAgo) {
    if (daysAgo == 0) return 'today';
    if (daysAgo == 1) return 'yesterday';
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[date.weekday - 1];
  }

  static String? _peakTimeWindow(FeedStats stats) {
    if (stats.hourlyScrollCounts.length < 24) return null;
    var max = 0;
    var peak = 0;
    for (var i = 0; i < stats.hourlyScrollCounts.length; i++) {
      if (stats.hourlyScrollCounts[i] > max) {
        max = stats.hourlyScrollCounts[i];
        peak = i;
      }
    }
    if (max < 2) return null;
    final start = _formatHour(peak);
    final end = _formatHour((peak + 2) % 24);
    return '$start and $end';
  }

  static int _longestSessionMinutes(FeedStats stats) {
    final totalMs = stats.totalWatchMs;
    final count = stats.totalCount;
    if (count <= 0 || totalMs <= 0) return 0;
    final avgSec = totalMs ~/ count ~/ 1000;
    return (avgSec * 3 / 60).ceil().clamp(1, 120);
  }

  static bool _hasNightSpike(FeedStats stats) {
    if (stats.hourlyScrollCounts.length < 24) return false;
    for (var h = 21; h <= 23; h++) {
      if (stats.hourlyScrollCounts[h] >= 3) return true;
    }
    return false;
  }

  static String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }
}

class _PeakDay {
  const _PeakDay(this.label, this.total);
  final String label;
  final int total;
}
