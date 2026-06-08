import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Focus Island — grows with focus minutes and attention score.
class FocusIsland extends StatelessWidget {
  const FocusIsland({
    super.key,
    required this.focusMinutes,
    required this.attentionScore,
    this.height = 140,
  });

  final int focusMinutes;
  final int attentionScore;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stage = _stage(focusMinutes, attentionScore);

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F2027), const Color(0xFF1A3A4A)]
              : [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(double.infinity, height - 40),
            painter: _IslandPainter(stage: stage, isDark: isDark),
          ),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _stageLabel(stage),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '${focusMinutes}m focus today',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _stage(int focusMin, int attention) {
    final combined = (focusMin / 10).floor() + (attention / 25).floor();
    return combined.clamp(0, 4);
  }

  String _stageLabel(int stage) {
    switch (stage) {
      case 0:
        return 'Empty Island';
      case 1:
        return 'Seedling';
      case 2:
        return 'Growing Forest';
      case 3:
        return 'Thriving Island';
      default:
        return 'Focus City';
    }
  }
}

class _IslandPainter extends CustomPainter {
  _IslandPainter({required this.stage, required this.isDark});

  final int stage;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF1B4965) : const Color(0xFF80DEEA);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45),
      waterPaint,
    );

    final landPaint = Paint()
      ..color = isDark ? const Color(0xFF2D6A4F) : const Color(0xFF66BB6A);
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * (0.35 - stage * 0.04),
        size.width * 0.85,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, landPaint);

    final treePaint = Paint()..color = const Color(0xFF1B4332);
    for (var i = 0; i <= stage; i++) {
      final x = size.width * (0.25 + i * 0.15);
      final treeH = 12.0 + stage * 8 + i * 4;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, size.height * 0.52),
          width: 4,
          height: treeH,
        ),
        treePaint,
      );
      canvas.drawCircle(
        Offset(x, size.height * 0.52 - treeH),
        6 + stage * 2.0,
        Paint()..color = Color.lerp(
          const Color(0xFF40916C),
          const Color(0xFF95D5B2),
          i / math.max(stage, 1),
        )!,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IslandPainter old) =>
      old.stage != stage || old.isDark != isDark;
}
