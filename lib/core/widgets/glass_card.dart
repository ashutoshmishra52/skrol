import 'package:flutter/material.dart';
import 'cute_3d_card.dart';

/// Kept for compatibility — delegates to Cute3DCard.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    if (gradient != null) {
      return Cute3DCard(
        padding: EdgeInsets.zero,
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      );
    }
    return Cute3DCard(
      padding: padding,
      borderRadius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }
}
