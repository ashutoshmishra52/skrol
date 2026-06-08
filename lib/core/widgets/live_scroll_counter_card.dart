import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Premium live counter card with animated count and color indicator.
class LiveScrollCounterCard extends StatelessWidget {
  const LiveScrollCounterCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.brandColor,
    this.subtitle,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color brandColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final levelColor = AppColors.scrollLevelColor(count);
    final cardBg = isDark ? const Color(0xFF1A1A22) : Colors.white;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: levelColor),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, animatedColor, child) {
        final accent = animatedColor ?? levelColor;
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1.5,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    width: 5,
                    color: accent,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: child!,
                ),
              ],
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: brandColor, size: 22),
              ),
              const Spacer(),
              _LevelBadge(count: count),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          _AnimatedCount(count: count),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnimatedCount extends StatefulWidget {
  const _AnimatedCount({required this.count});

  final int count;

  @override
  State<_AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<_AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.count;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _animation = IntTween(begin: _from, end: widget.count).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _from = oldWidget.count;
      _animation = IntTween(begin: _from, end: widget.count).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final value = _animation.value;
        final levelColor = AppColors.scrollLevelColor(value);
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: levelColor),
          duration: const Duration(milliseconds: 450),
          builder: (context, color, __) {
            return Text(
              '$value',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
                height: 1,
                color: color ?? levelColor,
              ),
            );
          },
        );
      },
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scrollLevelColor(count);
    final label = AppColors.scrollLevelLabel(count);

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: const Duration(milliseconds: 450),
      builder: (context, animatedColor, _) {
        final c = animatedColor ?? color;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
