import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/aetheris_insight_builder.dart';
import '../services/native_stats_service.dart';
import '../theme/app_colors.dart';
import 'cute_3d_card.dart';
import 'cute_brain_widget.dart';

class AetherisBrainPanel extends StatelessWidget {
  const AetherisBrainPanel({
    super.key,
    required this.userName,
    required this.stats,
    this.onTap,
  });

  final String userName;
  final FeedStats stats;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalCount;
    final reels = stats.reelsCount;
    final stateColor = AppColors.brainStateColor(reels);
    final insight = AetherisInsightBuilder.buildDailyInsight(
      userName: userName,
      stats: stats,
    );

    return Cute3DCard(
      onTap: onTap,
      shadowColor: stateColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CuteBrainWidget(reelsCount: reels, size: 96),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.coachName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: stateColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AetherisInsightBuilder.healthNote(reels),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: stateColor.withValues(alpha: 0.85),
                          ),
                    ),
                    const SizedBox(height: 10),
                    _SpeechBubble(text: insight),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStatPill(
                  label: 'Reels',
                  count: stats.reelsCount,
                  avg: stats.reelsAvgSeconds,
                  watchMs: stats.reelsWatchMs,
                  color: const Color(0xFFE1306C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatPill(
                  label: 'Shorts',
                  count: stats.shortsCount,
                  avg: stats.shortsAvgSeconds,
                  watchMs: stats.shortsWatchMs,
                  color: const Color(0xFFD50000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ScrollProgressBar(total: total, color: stateColor),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({
    required this.label,
    required this.count,
    required this.avg,
    required this.watchMs,
    required this.color,
  });

  final String label;
  final int count;
  final int avg;
  final int watchMs;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 2,
          right: 2,
          top: 3,
          bottom: -3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                avg > 0 ? '${avg}s each' : 'no avg yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (watchMs > 0)
                Text(
                  _formatWatch(watchMs),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatWatch(int ms) {
    final sec = ms ~/ 1000;
    if (sec < 60) return '$sec sec total';
    final min = sec ~/ 60;
    final rem = sec % 60;
    if (min < 60) {
      return rem > 0 ? '$min min $rem sec' : '$min min total';
    }
    final h = min ~/ 60;
    final m = min % 60;
    return m > 0 ? '$h hr $m min' : '$h hr total';
  }
}

class _ScrollProgressBar extends StatelessWidget {
  const _ScrollProgressBar({required this.total, required this.color});

  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (total / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TickLabel(label: '0', hintColor: Theme.of(context).hintColor),
            _TickLabel(label: '50', hintColor: Theme.of(context).hintColor),
            _TickLabel(label: '100', hintColor: Theme.of(context).hintColor),
          ],
        ),
      ],
    );
  }
}

class _TickLabel extends StatelessWidget {
  const _TickLabel({required this.label, required this.hintColor});

  final String label;
  final Color? hintColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: hintColor),
    );
  }
}
