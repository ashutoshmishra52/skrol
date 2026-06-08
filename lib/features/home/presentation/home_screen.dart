import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/providers/feed_stats_notifier.dart';
import '../../../../core/widgets/attention_score_ring.dart';
import '../../../../core/widgets/permission_banner.dart';
import '../../../../core/widgets/skrol_logo.dart';
import '../../../../core/widgets/premium_section_header.dart';
import '../../../../core/widgets/premium_activity_card.dart';
import '../../../../core/widgets/premium_insights_card.dart';
import '../../../../core/widgets/social_breakdown_card.dart';
import '../../../../core/widgets/day_comparison_cards.dart';
import '../../../../core/widgets/seven_day_scroll_timeline.dart';
import '../../../../core/widgets/focus_recommendation_card.dart';
import '../../../../core/utils/date_utils.dart' as app_date;
import '../../../../data/models/app_usage.dart';
import '../logic/home_insights.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refresh() async {
    await PermissionService().recheckUsageStatsAfterSettings();
    await PermissionService().checkAll();
    await ref.read(usageStatsServiceProvider).syncUsageData(days: 1);
    ref.invalidate(dashboardProvider);
    ref.invalidate(socialBreakdownProvider);
    ref.invalidate(scrollHistoryProvider);
    ref.invalidate(weeklyReportProvider);
    ref.invalidate(permissionStatusProvider);
    await ref.read(feedStatsNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final permissionAsync = ref.watch(permissionStatusProvider);
    final feedStats = ref.watch(feedStatsNotifierProvider);
    final socialAsync = ref.watch(socialBreakdownProvider);
    final historyAsync = ref.watch(scrollHistoryProvider);
    final weeklyAsync = ref.watch(weeklyReportProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dashboard = dashboardAsync.valueOrNull;
    final attention = dashboard?.attentionScore ?? 0;
    final focusMin = dashboard?.focusTimeMinutes ?? 0;
    final scrollTotal = feedStats.reelsCount + feedStats.shortsCount;
    final social = socialAsync.valueOrNull;
    final history = historyAsync.valueOrNull ?? [];
    final weeklyChange = weeklyAsync.valueOrNull?.screenTimeChange ?? 0;

    final insights = HomeInsightsBuilder.build(
      feedStats: feedStats,
      history: history,
      social: social ?? SocialMediaBreakdown.empty,
      focusMinutes: focusMin,
      weeklyScreenChange: weeklyChange,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0E) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, settings.userName, isDark),
                      const SizedBox(height: 32),
                      permissionAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (perm) {
                          if (perm.usageStatsGranted &&
                              perm.accessibilityGranted &&
                              perm.overlayGranted) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: PermissionBanner(
                              usageGranted: perm.usageStatsGranted,
                              accessibilityGranted: perm.accessibilityGranted,
                              overlayGranted: perm.overlayGranted,
                              onGrantUsage: () async {
                                await PermissionService().requestUsageStats();
                                ref.invalidate(permissionStatusProvider);
                              },
                              onGrantAccessibility: () async {
                                await PermissionService().openAccessibilitySettings();
                                ref.invalidate(permissionStatusProvider);
                              },
                              onGrantOverlay: () async {
                                await PermissionService().requestOverlayPermission();
                                ref.invalidate(permissionStatusProvider);
                              },
                            ),
                          );
                        },
                      ),

                      // 1. Attention Score
                      AttentionScoreRing(
                        attentionScore: attention,
                        scrollTotal: scrollTotal,
                      ).animate().fadeIn(duration: 450.ms),

                      const SizedBox(height: 36),

                      // 2. Today Summary
                      const PremiumSectionHeader(
                        title: 'Today Summary',
                        subtitle: 'Live scroll and focus metrics',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: Row(
                          children: [
                            Expanded(
                              child: PremiumActivityCard(
                                label: 'Reels Viewed',
                                value: '${feedStats.reelsCount}',
                                icon: Icons.movie_outlined,
                                accent: const Color(0xFFE1306C),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: PremiumActivityCard(
                                label: 'Shorts Viewed',
                                value: '${feedStats.shortsCount}',
                                icon: Icons.play_circle_outline_rounded,
                                accent: const Color(0xFFFF0000),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 150,
                        child: Row(
                          children: [
                            Expanded(
                              child: PremiumActivityCard(
                                label: 'Social Media',
                                value: app_date.DateUtils.formatMinutes(
                                  social?.totalMinutes ?? dashboard?.socialMediaMinutes ?? 0,
                                ),
                                icon: Icons.smartphone_outlined,
                                accent: AppColors.primary,
                                subtitle: 'Actual UsageStats data',
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: PremiumActivityCard(
                                label: 'Focus Time',
                                value: app_date.DateUtils.formatMinutes(focusMin),
                                icon: Icons.center_focus_strong_outlined,
                                accent: AppColors.metricGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 3. Yesterday Comparison
                      const PremiumSectionHeader(
                        title: 'Yesterday Comparison',
                        subtitle: 'See how today compares',
                      ),
                      const SizedBox(height: 16),
                      DayComparisonCards(history: history),

                      const SizedBox(height: 36),

                      // 4. Last 7 Days
                      const PremiumSectionHeader(
                        title: 'Last 7 Days',
                        subtitle: 'Reels and Shorts timeline',
                      ),
                      const SizedBox(height: 16),
                      SevenDayScrollTimeline(history: history),

                      const SizedBox(height: 36),

                      // 5. Social Media Breakdown
                      const PremiumSectionHeader(
                        title: 'Social Media Breakdown',
                        subtitle: 'Per-app screen time from UsageStats',
                      ),
                      const SizedBox(height: 16),
                      SocialBreakdownCard(
                        breakdown: social ?? SocialMediaBreakdown.empty,
                      ),

                      const SizedBox(height: 36),

                      // 6. Smart Insights
                      const PremiumSectionHeader(
                        title: 'Smart Insights',
                        subtitle: 'History-based patterns',
                      ),
                      const SizedBox(height: 16),
                      PremiumInsightsCard(insights: insights.smartInsights),
                      if (insights.behaviorInsights.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        PremiumInsightsCard(insights: insights.behaviorInsights),
                      ],

                      const SizedBox(height: 36),

                      // 7. Focus Recommendation
                      const PremiumSectionHeader(
                        title: 'Focus Recommendation',
                        subtitle: 'What to try next',
                      ),
                      const SizedBox(height: 16),
                      FocusRecommendationCard(recommendations: insights.recommendations),
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

  Widget _buildHeader(BuildContext context, String name, bool isDark) {
    final greeting = _greeting();
    final displayName = name.isNotEmpty ? name : 'there';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkrolLogoAvatar(size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/settings'),
          icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white70 : null),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
