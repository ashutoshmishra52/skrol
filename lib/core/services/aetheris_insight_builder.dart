import '../constants/app_constants.dart';
import '../services/native_stats_service.dart';

class AetherisInsightBuilder {
  static String buildDailyInsight({
    required String userName,
    required FeedStats stats,
  }) {
    final name = userName.trim().isNotEmpty ? userName.trim() : 'there';
    final total = stats.reelsCount + stats.shortsCount;
    final totalWatchMs = stats.reelsWatchMs + stats.shortsWatchMs;

    if (total == 0) {
      return 'Hi $name. No reels or shorts yet today. Your brain is resting well.';
    }

    final parts = <String>['Hi $name.'];

    if (stats.reelsCount > 0) {
      final avg = stats.reelsAvgSeconds > 0 ? stats.reelsAvgSeconds : 0;
      final watch = _formatDuration(stats.reelsWatchMs);
      if (avg > 0) {
        parts.add(
          'You watched ${stats.reelsCount} reel${stats.reelsCount == 1 ? '' : 's'} '
          'at about ${avg}s each, roughly $watch on Reels.',
        );
      } else {
        parts.add(
          'You scrolled ${stats.reelsCount} reel${stats.reelsCount == 1 ? '' : 's'} today.',
        );
      }
    }

    if (stats.shortsCount > 0) {
      final avg = stats.shortsAvgSeconds > 0 ? stats.shortsAvgSeconds : 0;
      final watch = _formatDuration(stats.shortsWatchMs);
      if (avg > 0) {
        parts.add(
          'Shorts: ${stats.shortsCount} viewed, ${avg}s average, about $watch total.',
        );
      } else {
        parts.add(
          'You scrolled ${stats.shortsCount} Short${stats.shortsCount == 1 ? '' : 's'} today.',
        );
      }
    }

    if (totalWatchMs > 0) {
      parts.add('Combined scroll time is ${_formatDuration(totalWatchMs)}.');
    }

    parts.add(_healthNote(total));

    return parts.join(' ');
  }

  static String healthNote(int total) => _healthNote(total);

  static String _healthNote(int total) {
    if (total >= 100) return 'Your brain needs a break soon.';
    if (total >= 50) return 'Scrolling is picking up. Try a short pause.';
    if (total >= 20) return 'Still within a healthy range. Stay mindful.';
    return 'Looking good. Keep it light today.';
  }

  static String _formatDuration(int ms) {
    if (ms <= 0) return '0s';
    final seconds = ms ~/ 1000;
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remSec = seconds % 60;
    if (minutes < 60) {
      return remSec > 0 ? '${minutes}m ${remSec}s' : '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    return remMin > 0 ? '${hours}h ${remMin}m' : '${hours}h';
  }

  static String coachLabel() => AppConstants.coachName;
}
