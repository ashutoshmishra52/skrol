import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../data/models/app_usage.dart';

class DayComparisonCards extends StatelessWidget {
  const DayComparisonCards({super.key, required this.history});

  final List<DailyScrollRecord> history;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = history.isNotEmpty ? history[0] : null;
    final yesterday = history.length > 1 ? history[1] : null;
    final twoDaysAgo = history.length > 2 ? history[2] : null;

    return Column(
      children: [
        if (today != null)
          _DayCard(
            title: 'Today',
            reels: today.reels,
            shorts: today.shorts,
            isDark: isDark,
            accent: AppColors.primary,
            compareReels: yesterday?.reels,
            compareShorts: yesterday?.shorts,
          ),
        if (yesterday != null) ...[
          const SizedBox(height: 12),
          _DayCard(
            title: 'Yesterday',
            reels: yesterday.reels,
            shorts: yesterday.shorts,
            isDark: isDark,
            accent: const Color(0xFF6366F1),
          ),
        ],
        if (twoDaysAgo != null) ...[
          const SizedBox(height: 12),
          _DayCard(
            title: '2 Days Ago',
            reels: twoDaysAgo.reels,
            shorts: twoDaysAgo.shorts,
            isDark: isDark,
            accent: isDark ? Colors.white38 : AppColors.textSecondaryLight,
          ),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.title,
    required this.reels,
    required this.shorts,
    required this.isDark,
    required this.accent,
    this.compareReels,
    this.compareShorts,
  });

  final String title;
  final int reels;
  final int shorts;
  final bool isDark;
  final Color accent;
  final int? compareReels;
  final int? compareShorts;

  @override
  Widget build(BuildContext context) {
    final reelsDelta = compareReels != null ? reels - compareReels! : null;
    final shortsDelta = compareShorts != null ? shorts - compareShorts! : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF1A1A22) : Colors.white,
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: accent,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Reels', value: reels)),
              Expanded(child: _Metric(label: 'Shorts', value: shorts)),
            ],
          ),
          if (reelsDelta != null || shortsDelta != null) ...[
            const SizedBox(height: 12),
            if (reelsDelta != null && reelsDelta != 0)
              _DeltaText(label: 'Reels', delta: reelsDelta),
            if (shortsDelta != null && shortsDelta != 0)
              _DeltaText(label: 'Shorts', delta: shortsDelta),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

class _DeltaText extends StatelessWidget {
  const _DeltaText({required this.label, required this.delta});

  final String label;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final color = delta > 0 ? AppColors.coral : AppColors.metricGreen;
    final sign = delta > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$sign$delta $label',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
