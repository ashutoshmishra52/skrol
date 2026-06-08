import 'package:flutter/material.dart';
import '../services/timeline_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart' as app_date;

class AppOpensCard extends StatelessWidget {
  const AppOpensCard({super.key, required this.stats});

  final List<AppOpenStat> stats;

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
          Text(
            'App Opens',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Duration + how many times you opened each app',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          if (stats.isEmpty)
            Text(
              'No data yet',
              style: TextStyle(
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
              ),
            )
          else
            ...stats.take(5).map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.appName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                        Text(
                          '${app_date.DateUtils.formatMinutes(s.minutes)} · ${s.openCount} opens',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
