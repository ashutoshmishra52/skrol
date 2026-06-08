import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../data/repositories/repositories.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (habits) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Tracker',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ).animate().fadeIn(),
                      const SizedBox(height: 8),
                      Text(
                        'Build consistency, one day at a time',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 24),
                      _buildWeeklyOverview(context, habits),
                      const SizedBox(height: 24),
                      ...habits.asMap().entries.map((entry) {
                        final index = entry.key;
                        final habit = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HabitCard(
                            habit: habit,
                            onToggle: () async {
                              await HabitRepository()
                                  .toggleHabitCompletion(habit, DateTime.now());
                              final todayKey = _todayKey();
                              if (!habit.completedDates.contains(todayKey)) {
                                await GamificationRepository()
                                    .addXp(10);
                                final progress =
                                    GamificationRepository().getProgress();
                                progress.totalHabitsCompleted++;
                                await GamificationRepository()
                                    .saveProgress(progress);
                              }
                              ref.invalidate(habitsProvider);
                              ref.invalidate(dashboardProvider);
                            },
                          )
                              .animate()
                              .fadeIn(delay: (80 * index).ms)
                              .slideX(begin: 0.05),
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
      ),
    );
  }

  Widget _buildWeeklyOverview(BuildContext context, List habits) {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    int totalCompleted = 0;
    int totalPossible = habits.length * 7;

    for (final habit in habits) {
      totalCompleted += habit.getWeeklyCompletions(weekStart) as int;
    }

    final progress = totalPossible > 0
        ? totalCompleted / totalPossible
        : 0.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This Week',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                '$totalCompleted / $totalPossible',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit, required this.onToggle});

  final dynamic habit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final todayKey = _todayKey();
    final isCompleted = habit.completedDates.contains(todayKey);
    final color = Color(
      int.parse(habit.color.replaceFirst('#', '0xFF')),
    );

    return GlassCard(
      onTap: onToggle,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? color
                  : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white)
                  : Text(habit.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.currentStreak} day streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Best: ${habit.longestStreak}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? color : Colors.transparent,
              border: Border.all(
                color: isCompleted ? color : Theme.of(context).hintColor,
                width: 2,
              ),
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }
}
