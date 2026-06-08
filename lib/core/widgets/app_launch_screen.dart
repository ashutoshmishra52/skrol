import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import 'skrol_logo.dart';

/// SKROL animated launch overlay — plays once on cold start.
class AppLaunchScreen extends StatefulWidget {
  const AppLaunchScreen({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<AppLaunchScreen> createState() => _AppLaunchScreenState();
}

class _AppLaunchScreenState extends State<AppLaunchScreen> {
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() => _exiting = true);
      Future<void>.delayed(const Duration(milliseconds: 520), () {
        if (mounted) widget.onComplete();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _exiting ? 0 : 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: _exiting ? 1.06 : 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _LaunchBackground(),
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _PulsingGlow()
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1, 1),
                            duration: 900.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 32),
                      const Text(
                        'SKROL',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.4,
                          color: Colors.white,
                          height: 1,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 350.ms, duration: 500.ms)
                          .slideY(begin: 0.25, end: 0, delay: 350.ms, duration: 500.ms),
                      const SizedBox(height: 10),
                      Text(
                        AppConstants.tagline,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 550.ms, duration: 450.ms)
                          .slideY(begin: 0.15, end: 0, delay: 550.ms, duration: 450.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingGlow extends StatefulWidget {
  const _PulsingGlow();

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brainPink.withValues(alpha: 0.2 + t * 0.25),
                blurRadius: 36 + t * 20,
                spreadRadius: 4 + t * 6,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1 + t * 0.15),
                blurRadius: 48 + t * 16,
              ),
            ],
          ),
          child: child,
        );
      },
      child: const SkrolLogo(
        size: 128,
        variant: SkrolLogoVariant.icon,
        showRing: true,
      ),
    );
  }
}

class _LaunchBackground extends StatelessWidget {
  const _LaunchBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.1,
          colors: [
            Color(0xFF1A1530),
            Color(0xFF0E0E12),
            Color(0xFF08080A),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _orb(AppColors.brainPink.withValues(alpha: 0.12), 220),
          ),
          Positioned(
            bottom: -40,
            left: -70,
            child: _orb(AppColors.primary.withValues(alpha: 0.1), 180),
          ),
        ],
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
