import 'package:flutter/material.dart';

/// SKROL brand palette with pink brain mascot accents.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFFEC4899);
  static const Color accent = Color(0xFF34D399);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color peach = Color(0xFFFFBE98);
  static const Color sky = Color(0xFF7DD3FC);
  static const Color brainPink = Color(0xFFFFB4D2);
  static const Color brainHealthy = Color(0xFFFF9ECD);
  static const Color brainCrack = Color(0xFFFF8A65);
  static const Color brainFried = Color(0xFFEF5350);

  static const Color darkBackground = Color(0xFF0E0E12);
  static const Color darkSurface = Color(0xFF141419);
  static const Color darkCard = Color(0xFF1A1A22);

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF6F6F8);

  static const Color chartPurple = Color(0xFF6366F1);
  static const Color metricGreen = Color(0xFF22C55E);
  static const Color metricBlue = Color(0xFF3B82F6);

  static const Color critical = Color(0xFFFF4757);
  static const Color poor = Color(0xFFFF6B35);
  static const Color average = Color(0xFFFFBE0B);
  static const Color great = Color(0xFF34D399);
  static const Color elite = Color(0xFF8B5CF6);

  static const Color textPrimaryDark = Color(0xFFF5F5F7);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF9CA3AF);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE9D5FF), Color(0xFFFCE7F3), Color(0xFFDBEAFE)],
  );

  static const LinearGradient brainGradientHealthy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFCCE5), Color(0xFFFF9ECD)],
  );

  static const LinearGradient brainGradientCrack = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFCCBC), Color(0xFFFF8A65)],
  );

  static const LinearGradient brainGradientFried = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFAB91), Color(0xFFEF5350)],
  );

  static Color scoreColor(int score) {
    if (score <= 20) return critical;
    if (score <= 40) return poor;
    if (score <= 60) return average;
    if (score <= 80) return great;
    return elite;
  }

  /// Scroll counter thresholds: 0–50 green, 51–99 yellow, 100+ red.
  static Color scrollLevelColor(int count) {
    if (count >= 100) return const Color(0xFFEF4444);
    if (count >= 51) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  static Color scrollLevelBackground(int count) {
    return scrollLevelColor(count).withValues(alpha: 0.12);
  }

  static String scrollLevelLabel(int count) {
    if (count >= 100) return 'High';
    if (count >= 51) return 'Moderate';
    return 'Low';
  }

  static Color scoreLabelColor(int score) {
    return scoreColor(score).withValues(alpha: 0.15);
  }

  static Color brainStateColor(int scrollTotal) {
    if (scrollTotal >= 70) return brainFried;
    if (scrollTotal >= 45) return brainCrack;
    if (scrollTotal >= 25) return brainCrack;
    if (scrollTotal >= 10) return peach;
    return brainHealthy;
  }

  static String brainStateLabel(int scrollTotal) {
    if (scrollTotal >= 100) return 'Brain needs rest';
    if (scrollTotal >= 50) return 'Brain is cracking';
    if (scrollTotal >= 20) return 'Slow down a bit';
    return 'Brain is healthy';
  }
}
