import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/feed_stats_notifier.dart';
import '../../../../core/widgets/live_scroll_counter_card.dart';
import '../../../../core/widgets/skrol_logo.dart';
import '../../../../core/widgets/activity_heatmap.dart';
import '../../../../core/widgets/usage_timeline.dart';
import '../../../../core/widgets/weekly_report_card.dart';
import '../../../../core/widgets/this_day_card.dart';
import '../../../../core/widgets/app_opens_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timelineAsync = ref.watch(timelineProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final appOpensAsync = ref.watch(appOpensProvider);
    final weeklyAsync = ref.watch(weeklyReportProvider);
    final thisDay = ref.watch(thisDayProvider);
    final feedStats = ref.watch(feedStatsNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(timelineProvider);
            ref.invalidate(heatmapDataProvider);
            ref.invalidate(appOpensProvider);
            ref.invalidate(weeklyReportProvider);
            ref.invalidate(heatmapDataProvider);
            ref.invalidate(dashboardProvider);
            ref.invalidate(socialBreakdownProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkrolLogoAvatar(size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Insights',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  'Where your attention went',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: LiveScrollCounterCard(
                              title: 'Reels',
                              count: feedStats.reelsCount,
                              icon: Icons.movie_outlined,
                              brandColor: const Color(0xFFE1306C),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: LiveScrollCounterCard(
                              title: 'Shorts',
                              count: feedStats.shortsCount,
                              icon: Icons.play_circle_outline_rounded,
                              brandColor: const Color(0xFFFF0000),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ThisDayCard(
                        reels: thisDay.reels,
                        shorts: thisDay.shorts,
                        socialMinutes: thisDay.socialMinutes,
                        focusMinutes: thisDay.focusMinutes,
                        mostUsedApp: thisDay.mostUsedApp,
                      ),
                      const SizedBox(height: 16),
                      weeklyAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (r) => WeeklyReportCard(
                          grade: r.grade,
                          screenTimeChange: r.screenTimeChange,
                          focusTimeChange: r.focusTimeChange,
                          mostDistractingApp: r.mostDistractingApp,
                          totalScreenMinutes: r.totalScreenMinutes,
                          totalFocusMinutes: r.totalFocusMinutes,
                        ),
                      ),
                      const SizedBox(height: 16),
                      heatmapAsync.when(
                        loading: () => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (map) => ActivityHeatmap(dailyData: map),
                      ),
                      const SizedBox(height: 16),
                      timelineAsync.when(
                        loading: () => const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (entries) => UsageTimeline(entries: entries, maxItems: 12),
                      ),
                      const SizedBox(height: 16),
                      appOpensAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (stats) => AppOpensCard(stats: stats),
                      ),
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
