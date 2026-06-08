import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_colors.dart';

class AttentionScoreRing extends StatelessWidget {
  const AttentionScoreRing({
    super.key,
    required this.attentionScore,
    this.scrollTotal = 0,
    this.size = 200,
  });

  final int attentionScore;
  final int scrollTotal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = AppColors.scrollLevelColor(scrollTotal);
    final label = AppColors.scrollLevelLabel(scrollTotal);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A24),
                  const Color(0xFF12121A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F8FC),
                ],
        ),
        border: Border.all(
          color: ringColor.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: ringColor),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, animatedColor, _) {
              final color = animatedColor ?? ringColor;
              return CircularPercentIndicator(
                radius: size / 2,
                lineWidth: 14,
                percent: (attentionScore / 100).clamp(0.0, 1.0),
                progressColor: color,
                backgroundColor: color.withValues(alpha: 0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animateFromLastPercent: true,
                animationDuration: 1200,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$attentionScore',
                      style: TextStyle(
                        fontSize: size * 0.24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Attention Score',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$scrollTotal items scrolled today',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
