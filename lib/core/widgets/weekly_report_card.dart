import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart' as app_date;

class WeeklyReportCard extends StatelessWidget {
  const WeeklyReportCard({
    super.key,
    required this.grade,
    required this.screenTimeChange,
    required this.focusTimeChange,
    required this.mostDistractingApp,
    required this.totalScreenMinutes,
    required this.totalFocusMinutes,
  });

  final String grade;
  final int screenTimeChange;
  final int focusTimeChange;
  final String mostDistractingApp;
  final int totalScreenMinutes;
  final int totalFocusMinutes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Your attention this week',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ReportRow(
            label: 'Social Media Screen Time',
            value: app_date.DateUtils.formatMinutes(totalScreenMinutes),
            change: screenTimeChange,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _ReportRow(
            label: 'Focus Time',
            value: app_date.DateUtils.formatMinutes(totalFocusMinutes),
            change: focusTimeChange,
            isDark: isDark,
            positiveIsGood: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Most distracting: ',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                mostDistractingApp,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareReport(),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share Report'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    final screenArrow = screenTimeChange <= 0 ? '↓' : '↑';
    final focusArrow = focusTimeChange >= 0 ? '↑' : '↓';
    Share.share(
      'SKROL Weekly Report\n'
      'Attention Grade: $grade\n\n'
      'Social Media Screen Time: ${app_date.DateUtils.formatMinutes(totalScreenMinutes)} ($screenArrow ${screenTimeChange.abs()}%)\n'
      'Focus Time: ${app_date.DateUtils.formatMinutes(totalFocusMinutes)} ($focusArrow ${focusTimeChange.abs()}%)\n'
      'Most Distracting: $mostDistractingApp',
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.label,
    required this.value,
    required this.change,
    required this.isDark,
    this.positiveIsGood = false,
  });

  final String label;
  final String value;
  final int change;
  final bool isDark;
  final bool positiveIsGood;

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    final color = isGood ? AppColors.accent : AppColors.coral;
    final arrow = isPositive ? '↑' : '↓';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$arrow ${change.abs()}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
