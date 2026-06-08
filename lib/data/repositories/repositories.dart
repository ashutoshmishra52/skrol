import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_packages.dart';
import '../../core/services/hive_service.dart';
import '../models/user_settings.dart';
import '../models/app_usage.dart';
import '../models/focus_session.dart';
import '../models/habit.dart';
import '../models/gamification.dart';

class SettingsRepository {
  static const _key = 'user_settings';

  UserSettings getSettings() {
    final stored = HiveService.settingsBox.get(_key);
    if (stored == null) {
      return UserSettings(createdAt: DateTime.now());
    }
    return _ensureCoreDistractingApps(stored);
  }

  UserSettings _ensureCoreDistractingApps(UserSettings settings) {
    if (!settings.onboardingComplete) return settings;

    final merged = AppPackages.socialMediaApps;
    if (settings.distractingApps.length == merged.length &&
        merged.every(settings.distractingApps.contains)) {
      return settings;
    }

    final updated = settings.copyWith(distractingApps: merged);
    HiveService.settingsBox.put(_key, updated);
    return updated;
  }

  Future<void> saveSettings(UserSettings settings) async {
    await HiveService.settingsBox.put(_key, settings);
  }

  Future<void> completeOnboarding({
    required String userName,
    required List<String> goals,
    required List<String> distractingApps,
  }) async {
    final settings = getSettings().copyWith(
      userName: userName,
      selectedGoals: goals,
      distractingApps: distractingApps,
      onboardingComplete: true,
    );
    await saveSettings(settings);
  }
}

class UsageRepository {
  Future<void> saveUsageRecord(AppUsageRecord record) async {
    final key = '${record.packageName}_${record.dateKey}';
    await HiveService.usageBox.put(key, record);
  }

  List<AppUsageRecord> getUsageForDate(DateTime date) {
    final dateKey = _dateKey(date);
    return HiveService.usageBox.values
        .where((r) => r.dateKey == dateKey)
        .where((r) => AppPackages.socialMediaApps.contains(r.packageName))
        .toList();
  }

  List<AppUsageRecord> getUsageForRange(DateTime start, DateTime end) {
    return HiveService.usageBox.values.where((r) {
      return !r.date.isBefore(start) && !r.date.isAfter(end);
    }).toList();
  }

  int getTotalScreenTime(DateTime date) {
    return getUsageForDate(date)
        .fold(0, (sum, r) => sum + r.usageMinutes);
  }

  int getSocialMediaTime(DateTime date, List<String> distractingApps) {
    return getUsageForDate(date)
        .where((r) => distractingApps.contains(r.packageName))
        .fold(0, (sum, r) => sum + r.usageMinutes);
  }

  Future<void> clearUsageForDate(DateTime date) async {
    final dateKey = _dateKey(date);
    final keysToDelete = HiveService.usageBox.keys
        .where((k) => k.toString().endsWith('_$dateKey'))
        .toList();
    for (final key in keysToDelete) {
      await HiveService.usageBox.delete(key);
    }
  }

  List<AppUsageRecord> getMostUsedApps(DateTime start, DateTime end,
      {int limit = 10}) {
    final usage = getUsageForRange(start, end)
        .where((r) => AppPackages.socialMediaApps.contains(r.packageName));
    final map = <String, AppUsageRecord>{};
    for (final record in usage) {
      if (map.containsKey(record.packageName)) {
        final existing = map[record.packageName]!;
        map[record.packageName] = AppUsageRecord(
          packageName: existing.packageName,
          appName: existing.appName,
          date: existing.date,
          usageMinutes: existing.usageMinutes + record.usageMinutes,
          category: existing.category,
          isDistraction: existing.isDistraction,
        );
      } else {
        map[record.packageName] = record;
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.usageMinutes.compareTo(a.usageMinutes));
    return sorted.take(limit).toList();
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> saveDailySummary({
    required DateTime date,
    int? appSwitchCount,
    int? socialMediaMinutes,
    int? focusMinutes,
    int? attentionScore,
    int? reelsCount,
    int? shortsCount,
  }) async {
    final key = 'summary_${_dateKey(date)}';
    final existing = HiveService.interventionsBox.get(key);
    final data = existing is Map
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{'date': date.toIso8601String()};

    if (appSwitchCount != null) data['appSwitchCount'] = appSwitchCount;
    if (socialMediaMinutes != null) data['socialMediaMinutes'] = socialMediaMinutes;
    if (focusMinutes != null) data['focusMinutes'] = focusMinutes;
    if (attentionScore != null) data['attentionScore'] = attentionScore;
    if (reelsCount != null) data['reelsCount'] = reelsCount;
    if (shortsCount != null) data['shortsCount'] = shortsCount;
    await HiveService.interventionsBox.put(key, data);
  }

  Map<String, dynamic>? getDailySummaryMap(DateTime date) {
    final key = 'summary_${_dateKey(date)}';
    final data = HiveService.interventionsBox.get(key);
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  int getAppSwitchCount(DateTime date) {
    return getDailySummaryMap(date)?['appSwitchCount'] as int? ?? 0;
  }

  int getHistoricalReels(DateTime date) {
    return getDailySummaryMap(date)?['reelsCount'] as int? ?? 0;
  }

  int getHistoricalShorts(DateTime date) {
    return getDailySummaryMap(date)?['shortsCount'] as int? ?? 0;
  }

  Map<String, int> getSocialBreakdownForDate(DateTime date) {
    final records = getUsageForDate(date);
    var instagram = 0;
    var youtube = 0;
    var facebook = 0;
    var x = 0;
    var snapchat = 0;
    var other = 0;

    for (final r in records) {
      switch (r.packageName) {
        case AppPackages.instagram:
          instagram += r.usageMinutes;
        case AppPackages.youtube:
          youtube += r.usageMinutes;
        case AppPackages.facebook:
        case 'com.facebook.lite':
          facebook += r.usageMinutes;
        case AppPackages.twitter:
          x += r.usageMinutes;
        case AppPackages.snapchat:
          snapchat += r.usageMinutes;
        default:
          other += r.usageMinutes;
      }
    }

    return {
      'instagram': instagram,
      'youtube': youtube,
      'facebook': facebook,
      'x': x,
      'snapchat': snapchat,
      'other': other,
      'total': instagram + youtube + facebook + x + snapchat + other,
    };
  }

  int getYesterdaySocialMedia(List<String> distractingApps) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getSocialMediaTime(yesterday, distractingApps);
  }

  int getYesterdayScreenTime() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getTotalScreenTime(yesterday);
  }
}

class FocusRepository {
  Future<void> saveSession(FocusSession session) async {
    await HiveService.focusBox.put(session.id, session);
  }

  List<FocusSession> getAllSessions() {
    return HiveService.focusBox.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  List<FocusSession> getSessionsForDate(DateTime date) {
    return getAllSessions().where((s) {
      return s.startTime.year == date.year &&
          s.startTime.month == date.month &&
          s.startTime.day == date.day;
    }).toList();
  }

  int getTotalFocusMinutes(DateTime date) {
    return getSessionsForDate(date)
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.actualDurationMinutes);
  }

  int getWeeklyFocusMinutes() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return getAllSessions()
        .where((s) =>
            s.completed &&
            !s.startTime.isBefore(
              DateTime(weekStart.year, weekStart.month, weekStart.day),
            ))
        .fold(0, (sum, s) => sum + s.actualDurationMinutes);
  }
}

class HabitRepository {
  Future<void> saveHabit(Habit habit) async {
    await HiveService.habitsBox.put(habit.id, habit);
  }

  List<Habit> getAllHabits() {
    return HiveService.habitsBox.values.toList();
  }

  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    final key = _dateKey(date);
    final dates = List<String>.from(habit.completedDates);
    if (dates.contains(key)) {
      dates.remove(key);
    } else {
      dates.add(key);
    }
    habit.completedDates = dates;
    _updateStreak(habit);
    await saveHabit(habit);
  }

  void _updateStreak(Habit habit) {
    final sorted = habit.completedDates.toList()..sort();
    if (sorted.isEmpty) {
      habit.currentStreak = 0;
      return;
    }

    int streak = 1;
    for (int i = sorted.length - 1; i > 0; i--) {
      final current = _parseDate(sorted[i]);
      final previous = _parseDate(sorted[i - 1]);
      if (current.difference(previous).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    habit.currentStreak = streak;
    if (streak > habit.longestStreak) {
      habit.longestStreak = streak;
    }
  }

  DateTime _parseDate(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class GamificationRepository {
  static const _key = 'user_progress';

  UserProgress getProgress() {
    return HiveService.gamificationBox.get(_key) ?? UserProgress();
  }

  Future<void> saveProgress(UserProgress progress) async {
    await HiveService.gamificationBox.put(_key, progress);
  }

  Future<int> addXp(int amount, {String? reason}) async {
    final progress = getProgress();
    progress.totalXp += amount;
    while (progress.totalXp >= _xpForLevel(progress.level + 1)) {
      progress.level++;
    }
    await saveProgress(progress);
    return amount;
  }

  int _xpForLevel(int level) {
    int xp = 0;
    for (int i = 1; i < level; i++) {
      xp += i * 100;
    }
    return xp;
  }

  List<Achievement> getAllAchievements() {
    return HiveService.achievementsBox.values.toList();
  }

  Future<List<Achievement>> unlockAchievement(String id) async {
    final progress = getProgress();
    if (progress.unlockedAchievements.contains(id)) return [];

    final achievement = HiveService.achievementsBox.get(id);
    if (achievement == null) return [];

    progress.unlockedAchievements = [
      ...progress.unlockedAchievements,
      id,
    ];
    await addXp(achievement.xpReward);
    await saveProgress(progress);
    return [achievement];
  }
}

class CoachRepository {
  Future<void> saveMessage(CoachMessage message) async {
    await HiveService.coachBox.put(message.id, message);
  }

  List<CoachMessage> getRecentMessages({int limit = 20}) {
    final messages = HiveService.coachBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return messages.take(limit).toList();
  }

  int get unreadCount =>
      HiveService.coachBox.values.where((m) => !m.read).length;
}

class ExportImportRepository {
  Future<Map<String, dynamic>> exportAllData() async {
    final settings = SettingsRepository().getSettings();
    return {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'userName': settings.userName,
        'selectedGoals': settings.selectedGoals,
        'distractingApps': settings.distractingApps,
        'themeMode': settings.themeMode,
      },
      'focusSessions': FocusRepository()
          .getAllSessions()
          .map((s) => {
                'id': s.id,
                'mode': s.mode,
                'startTime': s.startTime.toIso8601String(),
                'completed': s.completed,
                'actualDurationMinutes': s.actualDurationMinutes,
              })
          .toList(),
      'habits': HabitRepository()
          .getAllHabits()
          .map((h) => {
                'id': h.id,
                'name': h.name,
                'completedDates': h.completedDates,
                'currentStreak': h.currentStreak,
              })
          .toList(),
      'progress': {
        'totalXp': GamificationRepository().getProgress().totalXp,
        'level': GamificationRepository().getProgress().level,
      },
    };
  }

  Future<void> shareExport() async {
    final data = await exportAllData();
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await Share.share(json, subject: 'SKROL Data Export');
  }
}
