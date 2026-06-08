import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/date_utils.dart' as app_date;
import '../../data/models/app_usage.dart';

class SocialBreakdownCard extends StatelessWidget {
  const SocialBreakdownCard({super.key, required this.breakdown});

  final SocialMediaBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _Item('Instagram', breakdown.instagramMinutes, const Color(0xFFE1306C)),
      _Item('YouTube', breakdown.youtubeMinutes, const Color(0xFFFF0000)),
      _Item('Facebook', breakdown.facebookMinutes, const Color(0xFF1877F2)),
      _Item('X', breakdown.xMinutes, Colors.black87),
      _Item('Snapchat', breakdown.snapchatMinutes, const Color(0xFFFFFC00)),
      if (breakdown.otherMinutes > 0)
        _Item('Other Social', breakdown.otherMinutes, AppColors.primary),
    ].where((i) => i.minutes > 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Social Media',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            app_date.DateUtils.formatMinutes(breakdown.totalMinutes),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Text(
              'Grant Usage Access to see per-app screen time.',
              style: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondaryLight),
            )
          else
            ...items.map((item) => _BreakdownRow(item: item, isDark: isDark)),
        ],
      ),
    );
  }
}

class _Item {
  const _Item(this.label, this.minutes, this.color);
  final String label;
  final int minutes;
  final Color color;
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, required this.isDark});

  final _Item item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            app_date.DateUtils.formatMinutes(item.minutes),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
