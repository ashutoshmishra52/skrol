import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_packages.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/glass_card.dart';

class MonkModeScreen extends ConsumerStatefulWidget {
  const MonkModeScreen({super.key});

  @override
  ConsumerState<MonkModeScreen> createState() => _MonkModeScreenState();
}

class _MonkModeScreenState extends ConsumerState<MonkModeScreen> {
  int _selectedDuration = 60;
  bool _blockApps = true;
  bool _strictMode = true;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final distractingApps = settings.distractingApps;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7209B7).withValues(alpha: 0.2),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF7209B7),
                                  AppColors.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7209B7), AppColors.secondary],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7209B7)
                                    .withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.self_improvement,
                            size: 50,
                            color: Colors.white,
                          ),
                        ).animate().scale(
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Monk Mode',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ultimate focus. Zero distractions. Bonus XP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(height: 32),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duration',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [30, 60, 90, 120].map((mins) {
                                final selected = _selectedDuration == mins;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDuration = mins),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF7209B7)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF7209B7)
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: Text(
                                      '${mins}m',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : null,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Block Distracting Apps'),
                              subtitle: Text(
                                '${distractingApps.length} apps will be blocked',
                              ),
                              value: _blockApps,
                              onChanged: (v) =>
                                  setState(() => _blockApps = v),
                              activeColor: const Color(0xFF7209B7),
                            ),
                            const Divider(),
                            SwitchListTile(
                              title: const Text('Strict Mode'),
                              subtitle: const Text(
                                'No pausing allowed during session',
                              ),
                              value: _strictMode,
                              onChanged: (v) =>
                                  setState(() => _strictMode = v),
                              activeColor: const Color(0xFF7209B7),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Blocked Apps',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            ...distractingApps.take(8).map(
                                  (package) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.block,
                                            size: 16, color: AppColors.critical),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            AppPackages.displayName(package),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.1),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Earn +${AppConstants.xpFocusSession + AppConstants.xpMonkModeBonus} XP for completing Monk Mode',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      GradientButton(
                        label: 'Enter Monk Mode',
                        icon: Icons.self_improvement,
                        onPressed: () {
                          context.push('/focus/session', extra: {
                            'mode': 'monk',
                            'duration': _selectedDuration,
                            'isMonkMode': true,
                          });
                        },
                      ),
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
}
