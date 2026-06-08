import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/habit.dart';
import '../../data/models/gamification.dart';
import '../../data/models/app_usage.dart';
import '../../data/repositories/repositories.dart';
import '../constants/app_packages.dart';
import '../services/native_stats_service.dart';
import '../services/usage_stats_service.dart';
import '../services/app_services.dart';
import '../services/permission_service.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';
import '../services/timeline_service.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/activity_heatmap.dart';
import '../../data/models/challenge.dart';
import 'feed_stats_notifier.dart';

// Repositories
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());
final usageRepositoryProvider = Provider((ref) => UsageRepository());
final focusRepositoryProvider = Provider((ref) => FocusRepository());
final habitRepositoryProvider = Provider((ref) => HabitRepository());
final gamificationRepositoryProvider =
    Provider((ref) => GamificationRepository());
final coachRepositoryProvider = Provider((ref) => CoachRepository());
final exportRepositoryProvider = Provider((ref) => ExportImportRepository());

// Services
final usageStatsServiceProvider = Provider((ref) => UsageStatsService());
final aetherisCoachProvider = Provider((ref) => AetherisCoachService());
final interventionServiceProvider = Provider((ref) => InterventionService());
final achievementServiceProvider = Provider((ref) => AchievementService());
final notificationServiceProvider = Provider((ref) => NotificationService());

final permissionServiceProvider = Provider((ref) => PermissionService());

final permissionStatusProvider = FutureProvider<PermissionStatus>((ref) async {
  return ref.watch(permissionServiceProvider).checkAll();
});

// Settings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  SettingsNotifier(this._repo) : super(_repo.getSettings());

  final SettingsRepository _repo;

  Future<void> updateSettings(UserSettings settings) async {
    await _repo.saveSettings(settings);
    state = settings;
  }

  Future<void> setThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    await updateSettings(updated);
  }

  Future<void> setUserName(String name) async {
    final updated = state.copyWith(userName: name);
    await updateSettings(updated);
  }
}

// Theme
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings.themeMode) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

// Live app switch count — polls only while home screen is open, every 15s
final liveSwitchCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  while (true) {
    yield await NativeStatsService.getAppSwitchCount();
    await Future<void>.delayed(const Duration(seconds: 15));
  }
});

// Live reels/shorts — StateNotifier + EventChannel (instant updates)
// Defined in feed_stats_notifier.dart: feedStatsNotifierProvider, liveFeedStatsProvider

// Dashboard
final dashboardProvider =
    FutureProvider<DashboardData>((ref) async {
  final settings = ref.watch(settingsProvider);
  final usageRepo = ref.watch(usageRepositoryProvider);
  final focusRepo = ref.watch(focusRepositoryProvider);
  final habitRepo = ref.watch(habitRepositoryProvider);
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  final usageService = ref.watch(usageStatsServiceProvider);

  await usageService.syncUsageData(days: 1);

  final today = DateTime.now();
  final focusTime = focusRepo.getTotalFocusMinutes(today);
  final progress = gamificationRepo.getProgress();
  final habits = habitRepo.getAllHabits();
  final appSwitchCount = await NativeStatsService.getAppSwitchCount();
  final feedStats = await NativeStatsService.getFeedStats();
  final socialBreakdown = await NativeStatsService.getSocialMediaBreakdown();
  final socialMinutes = socialBreakdown.totalMinutes > 0
      ? socialBreakdown.totalMinutes
      : usageRepo.getSocialMediaTime(today, AppPackages.socialMediaApps);
  final yesterdaySocial =
      usageRepo.getYesterdaySocialMedia(AppPackages.socialMediaApps);
  final yesterdayScreen = yesterdaySocial;
  final weeklyFocus = focusRepo.getWeeklyFocusMinutes();

  final todayKey =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  final completedHabits =
      habits.where((h) => h.completedDates.contains(todayKey)).length;
  final habitRate = habits.isEmpty
      ? 0
      : ((completedHabits / habits.length) * 100).round();

  final attentionScore = ScoreCalculator.calculateAttentionScore(
    screenTimeMinutes: socialMinutes,
    focusMinutes: focusTime,
    socialMediaMinutes: socialMinutes,
    habitCompletionRate: habitRate,
    screenTimeGoal: settings.dailyScreenTimeGoalMinutes,
  );

  final dopamineScore = ScoreCalculator.calculateDopamineScore(
    socialMediaMinutes: socialMinutes,
    screenTimeMinutes: socialMinutes,
    appSwitchCount: appSwitchCount,
    focusMinutes: focusTime,
    habitCompletionRate: habitRate,
  );

  await usageRepo.saveDailySummary(
    date: today,
    appSwitchCount: appSwitchCount,
    socialMediaMinutes: socialMinutes,
    focusMinutes: focusTime,
    attentionScore: attentionScore,
    reelsCount: feedStats.reelsCount,
    shortsCount: feedStats.shortsCount,
  );

  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weeklyData = List.generate(7, (i) {
    final date = weekStart.add(Duration(days: i));
    return usageRepo
        .getSocialMediaTime(date, AppPackages.socialMediaApps)
        .toDouble();
  });

  final insights = _generateRealInsights(
    socialTime: socialMinutes,
    focusTime: focusTime,
    screenTime: socialMinutes,
    yesterdaySocial: yesterdaySocial,
    yesterdayScreen: yesterdayScreen,
    weeklyFocus: weeklyFocus,
    socialLimit: settings.dailySocialMediaLimitMinutes,
    focusGoal: settings.dailyFocusGoalMinutes,
    appSwitchCount: appSwitchCount,
  );

  final focusGoal = settings.dailyFocusGoalMinutes;

  // Update home widget with real data
  await HomeWidgetService.updateWidget(
    attentionScore: attentionScore,
    focusTime: app_date.DateUtils.formatMinutes(focusTime),
    focusStreak: progress.focusStreak,
    goalProgress: focusGoal > 0
        ? ((focusTime / focusGoal) * 100).clamp(0, 100).round()
        : 0,
  );

  return DashboardData(
    attentionScore: attentionScore,
    dopamineScore: dopamineScore,
    screenTimeMinutes: socialMinutes,
    focusTimeMinutes: focusTime,
    socialMediaMinutes: socialMinutes,
    focusStreak: progress.focusStreak,
    level: progress.level,
    totalXp: progress.totalXp,
    weeklyScreenTime: weeklyData,
    insights: insights,
    appSwitchCount: appSwitchCount,
    usagePermissionGranted: settings.usageStatsGranted,
  );
});

List<String> _generateRealInsights({
  required int socialTime,
  required int focusTime,
  required int screenTime,
  required int yesterdaySocial,
  required int yesterdayScreen,
  required int weeklyFocus,
  required int socialLimit,
  required int focusGoal,
  required int appSwitchCount,
}) {
  final insights = <String>[];

  if (yesterdaySocial > 0 && socialTime > 0) {
    final change =
        ((socialTime - yesterdaySocial) / yesterdaySocial * 100).round();
    if (change < 0) {
      insights.add(
        'Social media usage dropped ${change.abs()}% compared to yesterday.',
      );
    } else if (change > 0) {
      insights.add(
        'Social media usage increased $change% compared to yesterday.',
      );
    } else {
      insights.add('Social media usage is steady vs yesterday.');
    }
  } else if (socialTime > 0) {
    insights.add(
      'You\'ve spent ${app_date.DateUtils.formatMinutes(socialTime)} on social media today.',
    );
  }

  if (yesterdayScreen > 0 && screenTime > 0) {
    final change =
        ((screenTime - yesterdayScreen) / yesterdayScreen * 100).round();
    if (change < -5) {
      insights.add('Screen time down ${change.abs()}% vs yesterday — nice work!');
    }
  }

  if (focusTime > 0 && focusGoal > 0) {
    final remaining = focusGoal - focusTime;
    if (remaining > 0) {
      insights.add(
        '${app_date.DateUtils.formatMinutes(remaining)} left to hit today\'s focus goal.',
      );
    } else {
      insights.add('You hit today\'s focus goal! 🎯');
    }
  }

  if (weeklyFocus > 0) {
    insights.add(
      'Total focus this week: ${app_date.DateUtils.formatMinutes(weeklyFocus)}.',
    );
  }

  if (socialLimit > 0 && socialTime >= socialLimit) {
    insights.add(
      'You\'ve exceeded your ${socialLimit}m social media limit today.',
    );
  }

  if (appSwitchCount > 30) {
    insights.add(
      'High app switching today ($appSwitchCount times). Try a focus session.',
    );
  }

  if (insights.isEmpty) {
    insights.add(
      'Grant Usage Access permission to see your real screen time insights.',
    );
  }

  return insights.take(4).toList();
}

class DashboardData {
  DashboardData({
    required this.attentionScore,
    required this.dopamineScore,
    required this.screenTimeMinutes,
    required this.focusTimeMinutes,
    required this.socialMediaMinutes,
    required this.focusStreak,
    required this.level,
    required this.totalXp,
    required this.weeklyScreenTime,
    required this.insights,
    this.appSwitchCount = 0,
    this.usagePermissionGranted = false,
  });

  final int attentionScore;
  final int dopamineScore;
  final int screenTimeMinutes;
  final int focusTimeMinutes;
  final int socialMediaMinutes;
  final int focusStreak;
  final int level;
  final int totalXp;
  final List<double> weeklyScreenTime;
  final List<String> insights;
  final int appSwitchCount;
  final bool usagePermissionGranted;
}

// Focus
final activeFocusSessionProvider =
    StateNotifierProvider<FocusSessionNotifier, FocusSession?>((ref) {
  return FocusSessionNotifier(ref.watch(focusRepositoryProvider));
});

class FocusSessionNotifier extends StateNotifier<FocusSession?> {
  FocusSessionNotifier(this._repo) : super(null);

  final FocusRepository _repo;

  Future<void> startSession(FocusSession session) async {
    state = session;
    await _repo.saveSession(session);
  }

  Future<void> completeSession(int actualMinutes, {String notes = ''}) async {
    if (state == null) return;
    final session = state!;
    session.endTime = DateTime.now();
    session.actualDurationMinutes = actualMinutes;
    session.completed = true;
    session.notes = notes;
    await _repo.saveSession(session);
    state = null;
  }

  void cancelSession() {
    state = null;
  }
}

// Habits
final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  return ref.watch(habitRepositoryProvider).getAllHabits();
});

// Coach
final coachPromptReplyProvider = StateProvider<CoachMessage?>((ref) => null);

final coachMessagesProvider =
    FutureProvider<List<CoachMessage>>((ref) async {
  await ref.watch(usageStatsServiceProvider).syncUsageData(days: 1);
  final promptReply = ref.watch(coachPromptReplyProvider);
  final insights = await ref.watch(aetherisCoachProvider).generateInsights();
  if (promptReply != null) {
    return [promptReply, ...insights];
  }
  return insights;
});

// Achievements
final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  return ref.watch(gamificationRepositoryProvider).getAllAchievements();
});

final userProgressProvider = Provider<UserProgress>((ref) {
  return ref.watch(gamificationRepositoryProvider).getProgress();
});

// Usage
final todayUsageProvider = FutureProvider<List<AppUsageRecord>>((ref) async {
  final service = ref.watch(usageStatsServiceProvider);
  return service.getTodayUsage();
});

// Onboarding
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

class OnboardingState {
  OnboardingState({
    this.currentPage = 0,
    this.userName = '',
    this.selectedGoals = const [],
    this.selectedApps = const [],
  });

  final int currentPage;
  final String userName;
  final List<String> selectedGoals;
  final List<String> selectedApps;

  OnboardingState copyWith({
    int? currentPage,
    String? userName,
    List<String>? selectedGoals,
    List<String>? selectedApps,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      userName: userName ?? this.userName,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      selectedApps: selectedApps ?? this.selectedApps,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void nextPage() {
    state = state.copyWith(currentPage: state.currentPage + 1);
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void setUserName(String name) {
    state = state.copyWith(userName: name);
  }

  void toggleGoal(String goal) {
    final goals = List<String>.from(state.selectedGoals);
    if (goals.contains(goal)) {
      goals.remove(goal);
    } else {
      goals.add(goal);
    }
    state = state.copyWith(selectedGoals: goals);
  }

  void toggleApp(String app) {
    final apps = List<String>.from(state.selectedApps);
    if (apps.contains(app)) {
      apps.remove(app);
    } else {
      apps.add(app);
    }
    state = state.copyWith(selectedApps: apps);
  }

  void setSocialAppsOnly() {
    state = state.copyWith(selectedApps: List.from(AppPackages.socialMediaApps));
  }
}

// ── Insights providers ──

final timelineProvider = FutureProvider.autoDispose((ref) async {
  await ref.watch(usageStatsServiceProvider).syncUsageData(days: 1);
  return TimelineService().buildTodayTimeline();
});

final appOpensProvider = FutureProvider.autoDispose((ref) async {
  await ref.watch(usageStatsServiceProvider).syncUsageData(days: 1);
  return TimelineService().buildTodayAppOpens();
});

final heatmapDataProvider = FutureProvider.autoDispose<Map<String, HeatmapDayData>>((ref) async {
  ref.watch(feedStatsNotifierProvider);
  final repo = ref.watch(usageRepositoryProvider);
  final history = await NativeStatsService.getScrollHistory(days: 56);
  final today = DateTime.now();
  final map = <String, HeatmapDayData>{};

  for (final record in history) {
    final date = DateTime.tryParse('${record.dateKey}T12:00:00');
    if (date == null) continue;
    map[record.dateKey] = HeatmapDayData(
      reels: record.reels,
      shorts: record.shorts,
      socialMinutes: repo.getSocialMediaTime(date, AppPackages.socialMediaApps),
    );
  }

  for (var i = 0; i < 56; i++) {
    final date = today.subtract(Duration(days: i));
    final key = app_date.DateUtils.dateKey(date);
    map.putIfAbsent(
      key,
      () => HeatmapDayData(
        reels: repo.getHistoricalReels(date),
        shorts: repo.getHistoricalShorts(date),
        socialMinutes: repo.getSocialMediaTime(date, AppPackages.socialMediaApps),
      ),
    );
  }
  return map;
});

final thisDayProvider = Provider.autoDispose<({
  int reels,
  int shorts,
  int socialMinutes,
  int focusMinutes,
  String mostUsedApp,
})>((ref) {
  final feed = ref.watch(feedStatsNotifierProvider);
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  final social = ref.watch(socialBreakdownProvider).valueOrNull;
  final usageRepo = ref.watch(usageRepositoryProvider);
  final focusRepo = ref.watch(focusRepositoryProvider);
  final today = DateTime.now();

  final topApps = usageRepo.getMostUsedApps(today, today, limit: 1);
  final topApp = topApps.isNotEmpty ? topApps.first.appName : 'None';

  return (
    reels: feed.reelsCount,
    shorts: feed.shortsCount,
    socialMinutes: social?.totalMinutes ?? dashboard?.socialMediaMinutes ?? 0,
    focusMinutes: dashboard?.focusTimeMinutes ?? focusRepo.getTotalFocusMinutes(today),
    mostUsedApp: topApp,
  );
});

final weeklyReportProvider = FutureProvider.autoDispose((ref) async {
  final usageRepo = ref.watch(usageRepositoryProvider);
  final focusRepo = ref.watch(focusRepositoryProvider);
  final today = DateTime.now();

  var thisWeekScreen = 0;
  var lastWeekScreen = 0;
  var thisWeekFocus = 0;
  var lastWeekFocus = 0;

  for (var i = 0; i < 7; i++) {
    final d = today.subtract(Duration(days: i));
    thisWeekScreen += usageRepo.getSocialMediaTime(d, AppPackages.socialMediaApps);
    thisWeekFocus += focusRepo.getTotalFocusMinutes(d);
  }
  for (var i = 7; i < 14; i++) {
    final d = today.subtract(Duration(days: i));
    lastWeekScreen += usageRepo.getSocialMediaTime(d, AppPackages.socialMediaApps);
    lastWeekFocus += focusRepo.getTotalFocusMinutes(d);
  }

  final screenChange = lastWeekScreen > 0
      ? (((thisWeekScreen - lastWeekScreen) / lastWeekScreen) * 100).round()
      : 0;
  final focusChange = lastWeekFocus > 0
      ? (((thisWeekFocus - lastWeekFocus) / lastWeekFocus) * 100).round()
      : 0;

  final topApps = usageRepo.getMostUsedApps(
    today.subtract(const Duration(days: 6)),
    today,
    limit: 1,
  );
  final topApp = topApps.isNotEmpty ? topApps.first.appName : 'None';

  final dashboard = await ref.watch(dashboardProvider.future);
  final grade = _weeklyGrade(dashboard.attentionScore);

  return (
    grade: grade,
    screenTimeChange: screenChange,
    focusTimeChange: focusChange,
    mostDistractingApp: topApp,
    totalScreenMinutes: thisWeekScreen,
    totalFocusMinutes: thisWeekFocus,
  );
});

String _weeklyGrade(int score) {
  if (score >= 90) return 'A+';
  if (score >= 80) return 'A';
  if (score >= 70) return 'B+';
  if (score >= 60) return 'B';
  if (score >= 50) return 'C+';
  return 'C';
}

final challengesProvider = StateProvider<List<FocusChallenge>>((ref) {
  return ChallengeTemplates.defaults();
});

final socialBreakdownProvider = FutureProvider.autoDispose<SocialMediaBreakdown>((ref) async {
  await ref.watch(usageStatsServiceProvider).syncUsageData(days: 1);
  return NativeStatsService.getSocialMediaBreakdown();
});

final scrollHistoryProvider = FutureProvider.autoDispose<List<DailyScrollRecord>>((ref) async {
  ref.watch(feedStatsNotifierProvider);
  final history = await NativeStatsService.getScrollHistory(days: 7);
  final usageRepo = ref.read(usageRepositoryProvider);
  for (final day in history) {
    final date = DateTime.tryParse('${day.dateKey}T12:00:00');
    if (date == null) continue;
    await usageRepo.saveDailySummary(
      date: date,
      reelsCount: day.reels,
      shortsCount: day.shorts,
    );
  }
  return history;
});
