import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../data/models/focus_session.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  static const _modes = [
    _FocusModeInfo(
      type: FocusModeType.pomodoro,
      title: 'Pomodoro',
      subtitle: '25 min focus, 5 min break',
      icon: Icons.timer,
      duration: 25,
      color: AppColors.primary,
    ),
    _FocusModeInfo(
      type: FocusModeType.deepWork,
      title: 'Deep Work',
      subtitle: '90 min uninterrupted focus',
      icon: Icons.psychology,
      duration: 90,
      color: AppColors.secondary,
    ),
    _FocusModeInfo(
      type: FocusModeType.coding,
      title: 'Coding Session',
      subtitle: '45 min coding sprint',
      icon: Icons.code,
      duration: 45,
      color: AppColors.accent,
    ),
    _FocusModeInfo(
      type: FocusModeType.study,
      title: 'Study Session',
      subtitle: '50 min study block',
      icon: Icons.school,
      duration: 50,
      color: Color(0xFF00B4D8),
    ),
    _FocusModeInfo(
      type: FocusModeType.reading,
      title: 'Reading Session',
      subtitle: '30 min reading time',
      icon: Icons.menu_book,
      duration: 30,
      color: Color(0xFFE76F51),
    ),
    _FocusModeInfo(
      type: FocusModeType.exam,
      title: 'Exam Mode',
      subtitle: '120 min strict focus',
      icon: Icons.assignment,
      duration: 120,
      color: AppColors.critical,
    ),
    _FocusModeInfo(
      type: FocusModeType.monk,
      title: 'Monk Mode',
      subtitle: 'Ultimate distraction blocking',
      icon: Icons.self_improvement,
      duration: 60,
      color: Color(0xFF7209B7),
      isMonk: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Mode',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a focus mode to begin your session',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),
                    ..._modes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final mode = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FocusModeCard(
                          mode: mode,
                          onTap: () {
                            if (mode.isMonk) {
                              context.push('/focus/monk');
                            } else {
                              context.push('/focus/session', extra: {
                                'mode': mode.type.name,
                                'duration': mode.duration,
                                'isMonkMode': false,
                              });
                            }
                          },
                        )
                            .animate()
                            .fadeIn(delay: (100 * index).ms)
                            .slideX(begin: 0.1),
                      );
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusModeInfo {
  const _FocusModeInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.duration,
    required this.color,
    this.isMonk = false,
  });

  final FocusModeType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final int duration;
  final Color color;
  final bool isMonk;
}

class _FocusModeCard extends StatelessWidget {
  const _FocusModeCard({required this.mode, required this.onTap});

  final _FocusModeInfo mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: mode.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(mode.icon, color: mode.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mode.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (mode.isMonk) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              mode.color,
                              mode.color.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mode.subtitle,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${mode.duration}m',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: mode.color,
                  fontSize: 18,
                ),
              ),
              const Icon(Icons.play_circle_fill, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}
