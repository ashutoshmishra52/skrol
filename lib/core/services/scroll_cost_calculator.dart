import '../utils/date_utils.dart' as app_date;

class ScrollEquivalent {
  const ScrollEquivalent({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

class ScrollCostCalculator {
  ScrollCostCalculator._();

  static String formatScrollTime(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    return app_date.DateUtils.formatMinutes(totalMinutes);
  }

  /// Emotional equivalents for time spent scrolling.
  static List<ScrollEquivalent> equivalents(int scrollMinutes) {
    if (scrollMinutes <= 0) return const [];

    final pages = (scrollMinutes / 3).round().clamp(1, 999);
    final pomodoros = (scrollMinutes / 25).floor().clamp(0, 99);
    final walkKm = (scrollMinutes * 0.06).toStringAsFixed(1);
    final codingHours = (scrollMinutes / 45).toStringAsFixed(1);

    return [
      ScrollEquivalent(emoji: '📖', label: '$pages pages you could have read'),
      ScrollEquivalent(emoji: '💻', label: '$codingHours hrs of deep work'),
      ScrollEquivalent(emoji: '🚶', label: '${walkKm}km walk'),
      if (pomodoros > 0)
        ScrollEquivalent(emoji: '🍅', label: '$pomodoros Pomodoro sessions'),
    ];
  }
}
