import 'package:flutter/material.dart';
import '../services/timeline_service.dart';
import '../theme/app_colors.dart';

class UsageTimeline extends StatelessWidget {
  const UsageTimeline({
    super.key,
    required this.entries,
    this.maxItems = 5,
    this.onViewAll,
  });

  final List<TimelineEntry> entries;
  final int maxItems;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shown = entries.take(maxItems).toList();

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
              Text(
                'Scroll Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No sessions yet today. Usage Access required.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                ),
              ),
            )
          else
            ...shown.asMap().entries.map((e) {
              final isLast = e.key == shown.length - 1;
              return _TimelineRow(
                entry: e.value,
                isLast: isLast,
                isDark: isDark,
              );
            }),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLast,
    required this.isDark,
  });

  final TimelineEntry entry;
  final bool isLast;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _appColor(entry.packageName),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.formattedTime} · ${entry.appName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.durationMinutes} min',
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

  Color _appColor(String pkg) {
    if (pkg.contains('instagram')) return const Color(0xFFE1306C);
    if (pkg.contains('youtube')) return const Color(0xFFFF0000);
    if (pkg.contains('twitter')) return Colors.black;
    if (pkg.contains('facebook')) return const Color(0xFF1877F2);
    return AppColors.primary;
  }
}
