import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../data/models/app_usage.dart';

class SevenDayScrollTimeline extends StatelessWidget {
  const SevenDayScrollTimeline({super.key, required this.history});

  final List<DailyScrollRecord> history;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = List<DailyScrollRecord>.from(history.take(7))
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark ? const Color(0xFF14141A) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: days.map((day) {
          final date = DateTime.tryParse('${day.dateKey}T12:00:00') ?? DateTime.now();
          final label = _weekday(date);
          final todayKey = history.isNotEmpty ? history.first.dateKey : '';
          final isToday = day.dateKey == todayKey;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? AppColors.primary
                          : (isDark ? Colors.white54 : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                Expanded(
                  child: _Bar(
                    reels: day.reels,
                    shorts: day.shorts,
                    max: _maxTotal(history),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R ${day.reels}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE1306C),
                      ),
                    ),
                    Text(
                      'S ${day.shorts}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF0000),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static int _maxTotal(List<DailyScrollRecord> history) {
    if (history.isEmpty) return 1;
    return history.map((d) => d.totalScrolls).reduce((a, b) => a > b ? a : b).clamp(1, 999);
  }

  static String _weekday(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.reels,
    required this.shorts,
    required this.max,
    required this.isDark,
  });

  final int reels;
  final int shorts;
  final int max;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final total = reels + shorts;
    final widthFactor = total / max;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Container(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            FractionallySizedBox(
              widthFactor: widthFactor.clamp(0.0, 1.0),
              child: Row(
                children: [
                  if (reels > 0)
                    Expanded(
                      flex: reels,
                      child: Container(color: const Color(0xFFE1306C)),
                    ),
                  if (shorts > 0)
                    Expanded(
                      flex: shorts,
                      child: Container(color: const Color(0xFFFF0000)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
