import 'package:flutter/material.dart';
import '../services/scroll_cost_calculator.dart';
import '../theme/app_colors.dart';

class ScrollCostCard extends StatelessWidget {
  const ScrollCostCard({
    super.key,
    required this.scrollMinutes,
  });

  final int scrollMinutes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = ScrollCostCalculator.formatScrollTime(scrollMinutes);
    final equivalents = ScrollCostCalculator.equivalents(scrollMinutes);
    final levelColor = AppColors.scrollLevelColor(scrollMinutes);

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
            'Scroll Cost',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: levelColor),
            duration: const Duration(milliseconds: 450),
            builder: (context, color, _) {
              return RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    height: 1.3,
                  ),
                  children: [
                    const TextSpan(text: 'Today you spent '),
                    TextSpan(
                      text: time,
                      style: TextStyle(color: color ?? levelColor),
                    ),
                    const TextSpan(text: ' scrolling'),
                  ],
                ),
              );
            },
          ),
          if (equivalents.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              'That\'s equivalent to',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            ...equivalents.take(3).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(e.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
