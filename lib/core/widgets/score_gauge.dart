import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_colors.dart';

class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    required this.label,
    this.size = 140,
    this.subtitle,
  });

  final int score;
  final String label;
  final double size;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    final percent = score / 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: size / 2,
          lineWidth: 10,
          percent: percent.clamp(0.0, 1.0),
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: size * 0.08,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
            ],
          ),
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.15),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animateFromLastPercent: true,
          animationDuration: 1200,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
