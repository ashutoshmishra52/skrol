import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/habits/presentation/habits_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/coach/presentation/coach_screen.dart';
import '../../features/gamification/presentation/achievements_screen.dart';
import '../../features/focus/presentation/focus_session_screen.dart';
import '../../features/focus/presentation/monk_mode_screen.dart';
import '../../features/usage/presentation/usage_screen.dart';
import '../../features/intervention/presentation/intervention_screen.dart';
import '../../features/challenges/presentation/challenges_screen.dart';
import '../../features/debug/presentation/detection_debug_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsProvider);

  return GoRouter(
    initialLocation: settings.onboardingComplete ? '/home' : '/onboarding',
    redirect: (context, state) {
      final isOnboarding = state.matchedLocation == '/onboarding';
      if (!settings.onboardingComplete && !isOnboarding) {
        return '/onboarding';
      }
      if (settings.onboardingComplete && isOnboarding) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/focus',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FocusScreen(),
            ),
          ),
          GoRoute(
            path: '/habits',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HabitsScreen(),
            ),
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/coach',
        builder: (context, state) => const CoachScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/focus/session',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FocusSessionScreen(
            mode: extra?['mode'] ?? 'pomodoro',
            duration: extra?['duration'] ?? 25,
            isMonkMode: extra?['isMonkMode'] ?? false,
          );
        },
      ),
      GoRoute(
        path: '/focus/monk',
        builder: (context, state) => const MonkModeScreen(),
      ),
      GoRoute(
        path: '/usage',
        builder: (context, state) => const UsageScreen(),
      ),
      GoRoute(
        path: '/intervention',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return InterventionScreen(
            level: extra?['level'] ?? 'gentle',
            minutes: extra?['minutes'] ?? 15,
          );
        },
      ),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: '/debug/detection',
        builder: (context, state) => const DetectionDebugScreen(),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _calculateSelectedIndex(context);
    final inactive = isDark ? Colors.white38 : const Color(0xFF9CA3AF);

    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/focus'),
        elevation: 0,
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  selected: selected == 0,
                  inactiveColor: inactive,
                  onTap: () => context.go('/home'),
                ),
                _NavItem(
                  icon: Icons.timer_outlined,
                  activeIcon: Icons.timer_rounded,
                  selected: selected == 1,
                  inactiveColor: inactive,
                  onTap: () => context.go('/focus'),
                ),
                const SizedBox(width: 56),
                _NavItem(
                  icon: Icons.insights_outlined,
                  activeIcon: Icons.insights_rounded,
                  selected: selected == 3,
                  inactiveColor: inactive,
                  onTap: () => context.go('/analytics'),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  selected: selected == 4,
                  inactiveColor: inactive,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/focus')) return 1;
    if (location.startsWith('/habits')) return 2;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          selected ? activeIcon : icon,
          size: 26,
          color: selected ? AppColors.chartPurple : inactiveColor,
        ),
      ),
    );
  }
}
