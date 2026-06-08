import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// SKROL brand logo — pink brain mascot preserved.
class SkrolLogo extends StatelessWidget {
  const SkrolLogo({
    super.key,
    this.size = 120,
    this.variant = SkrolLogoVariant.full,
    this.borderRadius,
    this.showRing = false,
    this.showGlow = false,
  });

  final double size;
  final SkrolLogoVariant variant;
  final BorderRadius? borderRadius;
  final bool showRing;
  final bool showGlow;

  static const _fullAsset = 'assets/images/skrol_logo.png';
  static const _iconAsset = 'assets/icons/app_icon.png';

  String get _asset {
    switch (variant) {
      case SkrolLogoVariant.full:
        return _fullAsset;
      case SkrolLogoVariant.icon:
        return _iconAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    final image = ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        _asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _FallbackLogo(size: size),
      ),
    );

    Widget child = image;
    if (showRing) {
      child = Container(
        padding: EdgeInsets.all(size * 0.04),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: image,
      );
    }

    if (showGlow) {
      child = Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: size * 0.28,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: child,
      );
    }

    return child;
  }
}

enum SkrolLogoVariant { full, icon }

class SkrolBrandMark extends StatelessWidget {
  const SkrolBrandMark({
    super.key,
    this.logoSize = 120,
    this.showTagline = true,
    this.animated = false,
    this.showWelcome = false,
  });

  final double logoSize;
  final bool showTagline;
  final bool animated;
  final bool showWelcome;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final taglineColor = isDark ? Colors.white54 : AppColors.textSecondaryLight;

    Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkrolLogo(
          size: logoSize,
          variant: SkrolLogoVariant.full,
          showRing: true,
          showGlow: true,
        ),
        SizedBox(height: logoSize * 0.22),
        if (showWelcome) ...[
          Text(
            'Welcome to SKROL',
            style: TextStyle(
              fontSize: logoSize * 0.22,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          SizedBox(height: logoSize * 0.08),
        ],
        Text(
          'SKROL',
          style: TextStyle(
            fontSize: logoSize * 0.28,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: titleColor,
            height: 1,
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: logoSize * 0.06),
          Text(
            'Track Less. Live More.',
            style: TextStyle(
              fontSize: logoSize * 0.12,
              fontWeight: FontWeight.w500,
              color: taglineColor,
            ),
          ),
        ],
      ],
    );

    if (animated) {
      column = column
          .animate()
          .fadeIn(duration: 500.ms)
          .scale(
            begin: const Offset(0.88, 0.88),
            end: const Offset(1, 1),
            duration: 800.ms,
            curve: Curves.easeOutBack,
          );
    }

    return column;
  }
}

class SkrolLogoAvatar extends StatelessWidget {
  const SkrolLogoAvatar({
    super.key,
    this.size = 64,
    this.borderColor,
    this.borderWidth = 2,
  });

  final double size;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ring = borderColor ??
        (isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.08));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.04),
          child: SkrolLogo(
            size: size * 0.92,
            variant: SkrolLogoVariant.icon,
          ),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          colors: [AppColors.brainPink, AppColors.primary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
