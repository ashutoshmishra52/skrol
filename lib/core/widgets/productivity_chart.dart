import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProductivityChart extends StatelessWidget {
  const ProductivityChart({
    super.key,
    required this.values,
    required this.labels,
    this.unit = 'm',
  });

  final List<double> values;
  final List<String> labels;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final labelColor = isDark ? Colors.white38 : const Color(0xFFB0B0B8);

    if (values.isEmpty || values.every((v) => v == 0)) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No data yet',
            style: TextStyle(color: labelColor, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 10.0 : maxVal * 1.3;
    final peakIndex = values.indexOf(maxVal);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: gridColor,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > maxY) return const SizedBox.shrink();
                  return Text(
                    _formatY(value),
                    style: TextStyle(fontSize: 10, color: labelColor),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[i],
                      style: TextStyle(fontSize: 11, color: labelColor),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: peakIndex.toDouble(),
                color: AppColors.chartPurple.withValues(alpha: 0.15),
                strokeWidth: 40,
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                values.length,
                (i) => FlSpot(i.toDouble(), values[i]),
              ),
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.chartPurple,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) {
                  if (spot.x.toInt() != peakIndex) {
                    return FlDotCirclePainter(
                      radius: 0,
                      color: Colors.transparent,
                      strokeWidth: 0,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 6,
                    color: AppColors.chartPurple,
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  String _formatY(double value) {
    if (unit == 'm') {
      if (value < 60) return '${value.round()}m';
      final h = value ~/ 60;
      final m = (value % 60).round();
      return m > 0 ? '${h}h${m}m' : '${h}h';
    }
    return value.round().toString();
  }
}
