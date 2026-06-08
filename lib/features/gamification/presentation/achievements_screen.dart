import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final progress = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (achievements) {
          final unlocked = progress.unlockedAchievements.toSet();
          final unlockedList =
              achievements.where((a) => unlocked.contains(a.id)).toList();
          final lockedList =
              achievements.where((a) => !unlocked.contains(a.id)).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProgressHeader(progress: progress),
              const SizedBox(height: 24),
              Text(
                'Unlocked (${unlockedList.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              if (unlockedList.isEmpty)
                GlassCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Complete focus sessions and habits to unlock achievements!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                )
              else
                ...unlockedList.map(
                  (a) => _AchievementTile(achievement: a, unlocked: true),
                ),
              const SizedBox(height: 24),
              Text(
                'Locked (${lockedList.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ...lockedList.take(20).map(
                    (a) => _AchievementTile(achievement: a, unlocked: false),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress});

  final dynamic progress;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.secondary.withValues(alpha: 0.1),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                value: '${progress.level}',
                label: 'Level',
                subtitle: ScoreCalculator.levelTitle(progress.level),
              ),
              _StatColumn(
                value: '${progress.totalXp}',
                label: 'Total XP',
              ),
              _StatColumn(
                value: '${progress.unlockedAchievements.length}',
                label: 'Achievements',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.levelProgress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.xpInCurrentLevel} / ${progress.xpForNextLevel} XP to next level',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final String value;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).hintColor,
            ),
          ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
  });

  final dynamic achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(achievement.rarity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: unlocked
                    ? rarityColor.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  unlocked ? achievement.icon : '🔒',
                  style: TextStyle(
                    fontSize: 24,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: unlocked ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '+${achievement.xpReward}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? AppColors.accent : Colors.grey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  achievement.rarity,
                  style: TextStyle(
                    fontSize: 10,
                    color: rarityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'legendary':
        return AppColors.secondary;
      case 'rare':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }
}
