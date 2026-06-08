import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'cute_brain_widget.dart';

/// Circular profile avatar showing a 3D brain that gets tired as reels increase.
class BrainProfileAvatar extends StatelessWidget {
  const BrainProfileAvatar({
    super.key,
    required this.reelsCount,
    this.size = 48,
    this.onTap,
    this.showRing = true,
  });

  final int reelsCount;
  final double size;
  final VoidCallback? onTap;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final ringColor = AppColors.brainStateColor(reelsCount);

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: showRing
            ? Border.all(color: ringColor.withValues(alpha: 0.45), width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: 0.25),
            offset: Offset(0, size * 0.08),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: CuteBrainWidget(
            reelsCount: reelsCount,
            size: size * 0.88,
          ),
        ),
      ),
    );

    if (onTap == null) return avatar;

    return GestureDetector(onTap: onTap, child: avatar);
  }
}
