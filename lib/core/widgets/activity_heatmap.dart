import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart' as app_date;

class HeatmapDayData {
  const HeatmapDayData({
    this.reels = 0,
    this.shorts = 0,
    this.socialMinutes = 0,
  });

  final int reels;
  final int shorts;
  final int socialMinutes;

  int get totalScrolls => reels + shorts;
  int get intensity => totalScrolls > 0 ? totalScrolls : socialMinutes;
}

class ActivityHeatmap extends StatefulWidget {
  const ActivityHeatmap({
    super.key,
    required this.dailyData,
    this.weeks = 8,
  });

  final Map<String, HeatmapDayData> dailyData;
  final int weeks;

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  _HeatCell? _selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cells = _buildCells();
    final maxVal = cells.map((c) => c.data.intensity).fold(0, (a, b) => a > b ? a : b);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Heatmap',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a box to see that day\'s counts',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 18),
                    ...List.generate(7, (i) {
                      return SizedBox(
                        height: 18,
                        width: 14,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            dayLabels[i],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white30 : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(width: 6),
                ...List.generate(widget.weeks, (weekIdx) {
                  final weekStartDate = cells[weekIdx * 7].date;
                  final monthLabel = DateFormat('MMM').format(weekStartDate);
                  return Padding(
                    padding: EdgeInsets.only(right: weekIdx < widget.weeks - 1 ? 6 : 0),
                    child: Column(
                      children: [
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...List.generate(7, (dayIdx) {
                          final cellIdx = weekIdx * 7 + dayIdx;
                          if (cellIdx >= cells.length) {
                            return const SizedBox(width: 16, height: 16);
                          }
                          final cell = cells[cellIdx];
                          final isSelected = _selected?.dateKey == cell.dateKey;
                          final showDate = weekIdx >= widget.weeks - 2;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _selected = cell),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _cellColor(cell.data.intensity, maxVal, isDark),
                                      borderRadius: BorderRadius.circular(4),
                                      border: isSelected
                                          ? Border.all(
                                              color: AppColors.primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                if (showDate) ...[
                                  const SizedBox(width: 3),
                                  SizedBox(
                                    width: 18,
                                    child: Text(
                                      '${cell.date.day}',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isDark ? Colors.white30 : AppColors.textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 14),
            _DayDetailBar(cell: _selected!, isDark: isDark),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(AppColors.accent.withValues(alpha: 0.3), 'Low'),
              const SizedBox(width: 12),
              _legendDot(AppColors.average.withValues(alpha: 0.6), 'Med'),
              const SizedBox(width: 12),
              _legendDot(AppColors.coral, 'High'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Color _cellColor(int intensity, int max, bool isDark) {
    if (intensity <= 0) {
      return isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.04);
    }
    final ratio = max > 0 ? intensity / max : 0.0;
    if (ratio < 0.33) return AppColors.accent.withValues(alpha: 0.35 + ratio);
    if (ratio < 0.66) return AppColors.average.withValues(alpha: 0.5 + ratio * 0.3);
    return AppColors.coral.withValues(alpha: 0.6 + ratio * 0.4);
  }

  List<_HeatCell> _buildCells() {
    final today = DateTime.now();
    final totalDays = widget.weeks * 7;
    final start = today.subtract(Duration(days: totalDays - 1));
    final cells = <_HeatCell>[];

    for (var i = 0; i < totalDays; i++) {
      final date = start.add(Duration(days: i));
      final key = app_date.DateUtils.dateKey(date);
      cells.add(_HeatCell(
        date: date,
        dateKey: key,
        data: widget.dailyData[key] ?? const HeatmapDayData(),
      ));
    }
    return cells;
  }
}

class _HeatCell {
  _HeatCell({
    required this.date,
    required this.dateKey,
    required this.data,
  });

  final DateTime date;
  final String dateKey;
  final HeatmapDayData data;
}

class _DayDetailBar extends StatelessWidget {
  const _DayDetailBar({required this.cell, required this.isDark});

  final _HeatCell cell;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('EEE, MMM d, yyyy').format(cell.date);
    final d = cell.data;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatted,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('Reels', '${d.reels}', const Color(0xFFE1306C)),
              const SizedBox(width: 8),
              _chip('Shorts', '${d.shorts}', const Color(0xFFFF0000)),
              const SizedBox(width: 8),
              _chip('Total', '${d.totalScrolls}', AppColors.primary),
            ],
          ),
          if (d.socialMinutes > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Social: ${app_date.DateUtils.formatMinutes(d.socialMinutes)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
