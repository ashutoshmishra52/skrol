import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SkrolBackground extends StatelessWidget {
  const SkrolBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1025), Color(0xFF2D1B42), Color(0xFF1E1033)],
                  )
                : AppColors.heroGradient,
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: _blob(AppColors.secondary.withValues(alpha: 0.18), 180),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: _blob(AppColors.sky.withValues(alpha: 0.2), 140),
        ),
        Positioned(
          bottom: 100,
          right: -20,
          child: _blob(AppColors.brainPink.withValues(alpha: 0.15), 120),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
