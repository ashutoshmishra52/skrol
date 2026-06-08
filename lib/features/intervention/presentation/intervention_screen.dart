import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';

class InterventionScreen extends StatelessWidget {
  const InterventionScreen({
    super.key,
    required this.level,
    required this.minutes,
  });

  final String level;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final interventionLevel = InterventionLevel.values.firstWhere(
      (e) => e.name == level,
      orElse: () => InterventionLevel.gentle,
    );

    final service = InterventionService();
    final message =
        service.getInterventionMessage(interventionLevel, minutes);

    final isStrong = interventionLevel == InterventionLevel.strong;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _levelColor(interventionLevel).withValues(alpha: 0.2),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _levelColor(interventionLevel)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _levelIcon(interventionLevel),
                    size: 40,
                    color: _levelColor(interventionLevel),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _levelTitle(interventionLevel),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 48),
                if (isStrong) ...[
                  GradientButton(
                    label: 'Start Focus Mode',
                    icon: Icons.timer,
                    onPressed: () => context.go('/focus'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Dismiss'),
                  ),
                ] else ...[
                  GradientButton(
                    label: 'Take a Break',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/focus'),
                    child: const Text('Start Focus Session Instead'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _levelColor(InterventionLevel level) {
    switch (level) {
      case InterventionLevel.gentle:
        return AppColors.average;
      case InterventionLevel.motivational:
        return AppColors.primary;
      case InterventionLevel.challenge:
        return AppColors.poor;
      case InterventionLevel.strong:
        return AppColors.critical;
    }
  }

  IconData _levelIcon(InterventionLevel level) {
    switch (level) {
      case InterventionLevel.gentle:
        return Icons.notifications_active;
      case InterventionLevel.motivational:
        return Icons.emoji_objects;
      case InterventionLevel.challenge:
        return Icons.sports_martial_arts;
      case InterventionLevel.strong:
        return Icons.warning_amber_rounded;
    }
  }

  String _levelTitle(InterventionLevel level) {
    switch (level) {
      case InterventionLevel.gentle:
        return 'Gentle Reminder';
      case InterventionLevel.motivational:
        return 'Motivational Prompt';
      case InterventionLevel.challenge:
        return 'Focus Challenge';
      case InterventionLevel.strong:
        return 'Time to Refocus';
    }
  }
}
