import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WeeklyTrendChart extends StatelessWidget {
  const WeeklyTrendChart({
    super.key,
    required this.screenMinutes,
    required this.reelsToday,
    required this.shortsToday,
    required this.labels,
  });

  final List<double> screenMinutes;
  final int reelsToday;
  final int shortsToday;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final labelColor = isDark ? Colors.white38 : AppColors.textSecondaryLight;

    final scrollValues = List<double>.generate(7, (i) {
      final isToday = i == DateTime.now().weekday - 1;
      return isToday ? (reelsToday + shortsToday).toDouble() : 0;
    });

    final maxScreen = screenMinutes.isEmpty ? 0.0 : screenMinutes.reduce((a, b) => a > b ? a : b);
    final maxScroll = scrollValues.reduce((a, b) => a > b ? a : b);
    final maxY = [maxScreen, maxScroll, 10.0].reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isDark ? const Color(0xFF14141A) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > maxY) return const SizedBox.shrink();
                  return Text(
                    value >= 60 ? '${(value / 60).round()}h' : '${value.round()}',
                    style: TextStyle(fontSize: 10, color: labelColor),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == DateTime.now().weekday - 1 ? FontWeight.w700 : FontWeight.w500,
                        color: i == DateTime.now().weekday - 1
                            ? AppColors.primary
                            : labelColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: screenMinutes.length > i ? screenMinutes[i] : 0,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.5),
                      AppColors.primary,
                    ],
                  ),
                ),
                BarChartRodData(
                  toY: scrollValues[i],
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFE1306C).withValues(alpha: 0.5),
                      const Color(0xFFE1306C),
                    ],
                  ),
                ),
              ],
              barsSpace: 4,
            );
          }),
        ),
      ),
    );
  }
}
