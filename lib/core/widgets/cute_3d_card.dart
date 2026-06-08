import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Soft 3D card with bottom shadow slab — SKROL style.
class Cute3DCard extends StatelessWidget {
  const Cute3DCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.shadowColor,
    this.borderRadius = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? shadowColor;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? AppColors.darkCard : Colors.white);
    final slab = shadowColor ?? AppColors.primary.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 3D bottom slab
          Positioned(
            left: 4,
            right: 4,
            top: 6,
            bottom: -4,
            child: Container(
              decoration: BoxDecoration(
                color: slab,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.9),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
