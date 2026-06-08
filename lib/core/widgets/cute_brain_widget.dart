import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BrainHealth { healthy, tired, weary, cracking, fried }

BrainHealth brainHealthFromScroll(int total) {
  if (total >= 100) return BrainHealth.fried;
  if (total >= 50) return BrainHealth.cracking;
  if (total >= 25) return BrainHealth.weary;
  if (total >= 10) return BrainHealth.tired;
  return BrainHealth.healthy;
}

BrainHealth brainHealthFromReels(int reels) {
  if (reels >= 70) return BrainHealth.fried;
  if (reels >= 45) return BrainHealth.cracking;
  if (reels >= 25) return BrainHealth.weary;
  if (reels >= 10) return BrainHealth.tired;
  return BrainHealth.healthy;
}

class CuteBrainWidget extends StatelessWidget {
  const CuteBrainWidget({
    super.key,
    this.scrollTotal = 0,
    this.reelsCount,
    this.size = 140,
  });

  final int scrollTotal;
  final int? reelsCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final health = reelsCount != null
        ? brainHealthFromReels(reelsCount!)
        : brainHealthFromScroll(scrollTotal);
    final fatigue = reelsCount ?? scrollTotal;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrainPainter(health: health, fatigue: fatigue),
      ),
    );
  }
}

class _BrainPainter extends CustomPainter {
  _BrainPainter({required this.health, required this.fatigue});

  final BrainHealth health;
  final int fatigue;

  double get _slouch {
    return switch (health) {
      BrainHealth.healthy => 0,
      BrainHealth.tired => 0.02,
      BrainHealth.weary => 0.04,
      BrainHealth.cracking => 0.06,
      BrainHealth.fried => 0.09,
    };
  }

  double get _tilt {
    return switch (health) {
      BrainHealth.healthy => 0,
      BrainHealth.tired => 0.02,
      BrainHealth.weary => 0.04,
      BrainHealth.cracking => 0.06,
      BrainHealth.fried => 0.08,
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.78;
    final h = size.height * 0.72;

    final gradient = switch (health) {
      BrainHealth.healthy => AppColors.brainGradientHealthy,
      BrainHealth.tired => AppColors.brainGradientHealthy,
      BrainHealth.weary => AppColors.brainGradientCrack,
      BrainHealth.cracking => AppColors.brainGradientCrack,
      BrainHealth.fried => AppColors.brainGradientFried,
    };

    canvas.save();
    canvas.translate(0, h * _slouch);
    canvas.translate(cx, cy);
    canvas.rotate(_tilt);
    canvas.translate(-cx, -cy);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15 + _slouch)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: w * 0.9, height: h * 0.35),
      shadowPaint,
    );

    final brainPath = _brainShapePath(cx, cy, w, h);
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

    final depthPaint = Paint()
      ..color = const Color(0xFF4A1942).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(brainPath, depthPaint);
    canvas.restore();

    final brainPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(brainPath, brainPaint);

    if (health.index >= BrainHealth.weary.index) {
      _drawDarkCircles(canvas, cx, cy, w, h);
    }

    final groove = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final groovePath = Path()
      ..moveTo(cx, cy - h * 0.35)
      ..quadraticBezierTo(cx - w * 0.08, cy, cx, cy + h * 0.28);
    canvas.drawPath(groovePath, groove);

    final glossAlpha = switch (health) {
      BrainHealth.healthy => 0.45,
      BrainHealth.tired => 0.35,
      BrainHealth.weary => 0.25,
      BrainHealth.cracking => 0.18,
      BrainHealth.fried => 0.1,
    };
    final gloss = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: glossAlpha),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(cx - w * 0.1, cy - h * 0.2),
        width: w * 0.4,
        height: h * 0.28,
      ))
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - w * 0.12, cy - h * 0.18),
        width: w * 0.38,
        height: h * 0.24,
      ),
      gloss,
    );

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(brainPath, outline);

    _drawFace(canvas, cx, cy, w, h);

    if (health.index >= BrainHealth.cracking.index) {
      _drawCracks(canvas, cx, cy, w, h, health == BrainHealth.fried);
    }

    if (health == BrainHealth.fried) {
      _drawExhaustionSteam(canvas, cx, cy - h * 0.5, w);
    }

    canvas.restore();
  }

  void _drawDarkCircles(Canvas canvas, double cx, double cy, double w, double h) {
    final bagPaint = Paint()
      ..color = const Color(0xFF4A1942).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * w * 0.14, cy + h * 0.06),
          width: w * 0.12,
          height: h * 0.07,
        ),
        bagPaint,
      );
    }
  }

  void _drawExhaustionSteam(Canvas canvas, double cx, double topY, double w) {
    final steam = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final x = cx + i * w * 0.12;
      final path = Path()
        ..moveTo(x, topY)
        ..quadraticBezierTo(x + 4, topY - 8, x - 2, topY - 16);
      canvas.drawPath(path, steam);
    }
  }

  Path _brainShapePath(double cx, double cy, double w, double h) {
    final squash = 1.0 + _slouch * 0.8;
    final path = Path();
    path.moveTo(cx, cy - h * 0.45);
    path.cubicTo(
      cx + w * 0.55, cy - h * 0.5,
      cx + w * 0.52, cy + h * 0.05,
      cx + w * 0.38, cy + h * 0.35 * squash,
    );
    path.cubicTo(
      cx + w * 0.2, cy + h * 0.52 * squash,
      cx - w * 0.2, cy + h * 0.52 * squash,
      cx - w * 0.38, cy + h * 0.35 * squash,
    );
    path.cubicTo(
      cx - w * 0.52, cy + h * 0.05,
      cx - w * 0.55, cy - h * 0.5,
      cx, cy - h * 0.45,
    );
    path.close();

    for (final side in [-1.0, 1.0]) {
      path.addOval(Rect.fromCenter(
        center: Offset(cx + side * w * 0.28, cy - h * 0.08),
        width: w * 0.28,
        height: h * 0.32,
      ));
    }
    return path;
  }

  void _drawFace(Canvas canvas, double cx, double cy, double w, double h) {
    final eyeY = cy - h * 0.02 + h * _slouch * 0.3;
    final eyeOffset = w * 0.14;
    final eyeColor = const Color(0xFF4A1942);

    switch (health) {
      case BrainHealth.healthy:
        _drawOpenEyes(canvas, cx, eyeY, eyeOffset, w, eyeColor);
        _drawSmile(canvas, cx, cy, w, h, eyeColor);
      case BrainHealth.tired:
        _drawHalfClosedEyes(canvas, cx, eyeY, eyeOffset, w, eyeColor);
        _drawFlatMouth(canvas, cx, cy, w, h, eyeColor);
      case BrainHealth.weary:
        _drawHalfClosedEyes(canvas, cx, eyeY, eyeOffset, w, eyeColor);
        _drawDroopLines(canvas, cx, eyeY, eyeOffset, w, eyeColor);
        _drawFlatMouth(canvas, cx, cy, w, h, eyeColor);
      case BrainHealth.cracking:
        _drawTiredDots(canvas, cx, eyeY, eyeOffset, w, eyeColor);
        _drawFlatMouth(canvas, cx, cy, w, h, eyeColor);
      case BrainHealth.fried:
        _drawXEye(canvas, Offset(cx - eyeOffset, eyeY), w * 0.07);
        _drawXEye(canvas, Offset(cx + eyeOffset, eyeY), w * 0.07);
        _drawFrown(canvas, cx, cy, w, h, eyeColor);
    }
  }

  void _drawOpenEyes(Canvas canvas, double cx, double eyeY, double offset, double w, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(cx - offset, eyeY), w * 0.055, paint);
    canvas.drawCircle(Offset(cx + offset, eyeY), w * 0.055, paint);
  }

  void _drawHalfClosedEyes(Canvas canvas, double cx, double eyeY, double offset, double w, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final ex = cx + side * offset;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(ex, eyeY), width: w * 0.11, height: w * 0.08),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        paint,
      );
    }
  }

  void _drawDroopLines(Canvas canvas, double cx, double eyeY, double offset, double w, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(cx + side * offset - w * 0.04, eyeY + w * 0.05),
        Offset(cx + side * offset + w * 0.04, eyeY + w * 0.05),
        paint,
      );
    }
  }

  void _drawTiredDots(Canvas canvas, double cx, double eyeY, double offset, double w, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(cx - offset, eyeY), w * 0.045, paint);
    canvas.drawCircle(Offset(cx + offset, eyeY), w * 0.045, paint);
  }

  void _drawSmile(Canvas canvas, double cx, double cy, double w, double h, Color color) {
    final smile = Path()
      ..moveTo(cx - w * 0.12, cy + h * 0.12)
      ..quadraticBezierTo(cx, cy + h * 0.22, cx + w * 0.12, cy + h * 0.12);
    canvas.drawPath(
      smile,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFlatMouth(Canvas canvas, double cx, double cy, double w, double h, Color color) {
    canvas.drawLine(
      Offset(cx - w * 0.1, cy + h * 0.14),
      Offset(cx + w * 0.1, cy + h * 0.14),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawFrown(Canvas canvas, double cx, double cy, double w, double h, Color color) {
    final frown = Path()
      ..moveTo(cx - w * 0.1, cy + h * 0.2)
      ..quadraticBezierTo(cx, cy + h * 0.1, cx + w * 0.1, cy + h * 0.2);
    canvas.drawPath(
      frown,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawXEye(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = const Color(0xFF4A1942)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + Offset(-r, -r), center + Offset(r, r), paint);
    canvas.drawLine(center + Offset(r, -r), center + Offset(-r, r), paint);
  }

  void _drawCracks(Canvas canvas, double cx, double cy, double w, double h, bool heavy) {
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: heavy ? 0.85 : 0.6)
      ..strokeWidth = heavy ? 2.5 : 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cracks = heavy ? 6 : 3;
    for (var i = 0; i < cracks; i++) {
      final angle = (i / cracks) * math.pi * 2 + 0.3;
      final start = Offset(cx + math.cos(angle) * w * 0.1, cy + math.sin(angle) * h * 0.05);
      final end = Offset(
        cx + math.cos(angle) * w * 0.35,
        cy + math.sin(angle) * h * 0.28,
      );
      canvas.drawLine(start, end, crackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrainPainter old) =>
      old.health != health || old.fatigue != fatigue;
}
