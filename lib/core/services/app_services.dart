import 'dart:math';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_packages.dart';
import '../../core/services/hive_service.dart';
import '../../data/models/app_usage.dart';
import '../../data/models/gamification.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/repositories.dart';

class ScoreCalculator {
  static int calculateAttentionScore({
    required int screenTimeMinutes,
    required int focusMinutes,
    required int socialMediaMinutes,
    required int habitCompletionRate,
    required int screenTimeGoal,
  }) {
    final screenScore = max(
      0,
      100 - ((screenTimeMinutes / screenTimeGoal.clamp(1, 999)) * 100).round(),
    );
    final focusScore =
        min(100, (focusMinutes / 120 * 100).round());
    final socialScore = max(
      0,
      100 - ((socialMediaMinutes / 60) * 100).round(),
    );
    final habitScore = habitCompletionRate;

    return ((screenScore * 0.25) +
            (focusScore * 0.30) +
            (socialScore * 0.25) +
            (habitScore * 0.20))
        .round()
        .clamp(0, 100);
  }

  static int calculateDopamineScore({
    required int socialMediaMinutes,
    required int screenTimeMinutes,
    required int appSwitchCount,
    required int focusMinutes,
    required int habitCompletionRate,
  }) {
    final socialPenalty = min(40, (socialMediaMinutes / 2).round());
    final screenPenalty = min(25, (screenTimeMinutes / 10).round());
    final switchPenalty = min(20, (appSwitchCount / 5).round());
    final focusBonus = min(30, (focusMinutes / 4).round());
    final habitBonus = min(20, (habitCompletionRate / 5).round());

    return (50 - socialPenalty - screenPenalty - switchPenalty + focusBonus + habitBonus)
        .clamp(0, 100);
  }

  static String dopamineLabel(int score) {
    if (score <= 20) return 'Critical';
    if (score <= 40) return 'Poor';
    if (score <= 60) return 'Average';
    if (score <= 80) return 'Great';
    return 'Elite';
  }

  static String levelTitle(int level) {
    final titles = AppConstants.levelTitles;
    String title = 'Beginner';
    for (final entry in titles.entries) {
      if (level >= entry.key) title = entry.value;
    }
    return title;
  }
}

class AetherisCoachService {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final UsageRepository _usageRepo = UsageRepository();
  final FocusRepository _focusRepo = FocusRepository();
  final HabitRepository _habitRepo = HabitRepository();
  final GamificationRepository _gamificationRepo = GamificationRepository();
  final CoachRepository _coachRepo = CoachRepository();
  final Random _random = Random();

  Future<List<CoachMessage>> generateInsights() async {
    final messages = <CoachMessage>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final settings = _settingsRepo.getSettings();
    final name = settings.userName.isNotEmpty ? settings.userName : 'there';

    if (!settings.usageStatsGranted) {
      return _saveAndReturn([
        CoachMessage(
          id: 'perm_${now.millisecondsSinceEpoch}',
          message:
              'Hi $name — enable Usage Access so I can read your real screen time and give you personalized guidance.',
          timestamp: now,
          type: 'reminder',
          actionLabel: 'Open Settings',
          actionRoute: '/settings',
        ),
      ]);
    }

    final screenTime = _usageRepo.getTotalScreenTime(today);
    final socialTime =
        _usageRepo.getSocialMediaTime(today, AppPackages.socialMediaApps);
    final focusTime = _focusRepo.getTotalFocusMinutes(today);
    final progress = _gamificationRepo.getProgress();
    final appSwitches = _usageRepo.getAppSwitchCount(today);
    final yesterdaySocial =
        _usageRepo.getYesterdaySocialMedia(AppPackages.socialMediaApps);
    final yesterdayScreen = _usageRepo.getYesterdayScreenTime();
    final topApps = _usageRepo.getMostUsedApps(today, today, limit: 3);

    if (screenTime == 0 && socialTime == 0) {
      messages.add(CoachMessage(
        id: 'sync_${now.millisecondsSinceEpoch}',
        message:
            'No usage data synced yet, $name. Pull down on Home to refresh, or check Usage Access is enabled.',
        timestamp: now,
        type: 'tip',
        actionLabel: 'View Usage',
        actionRoute: '/usage',
      ));
    } else {
      messages.add(CoachMessage(
        id: 'summary_${now.millisecondsSinceEpoch}',
        message:
            'Today: ${_fmt(screenTime)} screen time, ${_fmt(focusTime)} focused, ${_fmt(socialTime)} on social apps.',
        timestamp: now,
        type: 'tip',
      ));
    }

    if (socialTime >= settings.dailySocialMediaLimitMinutes) {
      messages.add(CoachMessage(
        id: 'social_limit_${now.millisecondsSinceEpoch}',
        message:
            'You\'ve hit your ${_fmt(settings.dailySocialMediaLimitMinutes)} social limit (${_fmt(socialTime)} used). A 15-min focus sprint could help reset.',
        timestamp: now,
        type: 'warning',
        actionLabel: 'Start Focus',
        actionRoute: '/focus',
      ));
    } else if (socialTime >= 15) {
      messages.add(CoachMessage(
        id: 'scroll_${now.millisecondsSinceEpoch}',
        message:
            '${_fmt(socialTime)} on social apps so far — ${_fmt(settings.dailySocialMediaLimitMinutes - socialTime)} left before your limit.',
        timestamp: now,
        type: 'warning',
        actionLabel: 'Start Focus',
        actionRoute: '/focus',
      ));
    }

    if (yesterdaySocial > 0 && socialTime > 0) {
      final change =
          ((socialTime - yesterdaySocial) / yesterdaySocial * 100).round();
      if (change <= -10) {
        messages.add(CoachMessage(
          id: 'social_down_${now.millisecondsSinceEpoch}',
          message:
              'Social time is down ${change.abs()}% vs yesterday. Nice discipline, $name.',
          timestamp: now,
          type: 'success',
        ));
      } else if (change >= 15) {
        messages.add(CoachMessage(
          id: 'social_up_${now.millisecondsSinceEpoch}',
          message:
              'Social time is up $change% vs yesterday. Want to protect the rest of your day with focus mode?',
          timestamp: now,
          type: 'warning',
          actionLabel: 'Start Focus',
          actionRoute: '/focus',
        ));
      }
    }

    if (topApps.isNotEmpty && topApps.first.isDistraction) {
      final top = topApps.first;
      messages.add(CoachMessage(
        id: 'top_app_${now.millisecondsSinceEpoch}',
        message:
            '${top.appName} is your top distraction today at ${_fmt(top.usageMinutes)}. Consider a break from it.',
        timestamp: now,
        type: 'warning',
        actionLabel: 'View Usage',
        actionRoute: '/usage',
      ));
    }

    if (appSwitches >= 40) {
      messages.add(CoachMessage(
        id: 'switches_${now.millisecondsSinceEpoch}',
        message:
            '$appSwitches app switches today — your attention is fragmented. Try a 25-min deep work block.',
        timestamp: now,
        type: 'tip',
        actionLabel: 'Start Focus',
        actionRoute: '/focus',
      ));
    }

    if (focusTime >= settings.dailyFocusGoalMinutes && settings.dailyFocusGoalMinutes > 0) {
      messages.add(CoachMessage(
        id: 'focus_goal_${now.millisecondsSinceEpoch}',
        message:
            'You hit your ${_fmt(settings.dailyFocusGoalMinutes)} focus goal! ${_fmt(focusTime)} logged today.',
        timestamp: now,
        type: 'success',
      ));
    } else if (focusTime >= 60) {
      messages.add(CoachMessage(
        id: 'great_${now.millisecondsSinceEpoch}',
        message: 'Solid work — ${_fmt(focusTime)} of focused time today, $name.',
        timestamp: now,
        type: 'success',
      ));
    } else if (focusTime == 0 && now.hour >= 14) {
      messages.add(CoachMessage(
        id: 'no_focus_${now.millisecondsSinceEpoch}',
        message:
            'No focus sessions yet today. Even 15 minutes now moves you toward your ${_fmt(settings.dailyFocusGoalMinutes)} goal.',
        timestamp: now,
        type: 'reminder',
        actionLabel: 'Start Focus',
        actionRoute: '/focus',
      ));
    }

    if (screenTime > settings.dailyScreenTimeGoalMinutes) {
      messages.add(CoachMessage(
        id: 'screen_goal_${now.millisecondsSinceEpoch}',
        message:
            'Screen time (${_fmt(screenTime)}) is above your ${_fmt(settings.dailyScreenTimeGoalMinutes)} daily goal.',
        timestamp: now,
        type: 'warning',
      ));
    } else if (yesterdayScreen > 0 && screenTime > 0) {
      final diff = screenTime - yesterdayScreen;
      if (diff <= -15) {
        messages.add(CoachMessage(
          id: 'screen_down_${now.millisecondsSinceEpoch}',
          message:
              'Screen time is ${_fmt(diff.abs())} lower than yesterday. Keep that momentum.',
          timestamp: now,
          type: 'success',
        ));
      }
    }

    if (progress.focusStreak >= 3) {
      messages.add(CoachMessage(
        id: 'streak_${now.millisecondsSinceEpoch}',
        message:
            '${progress.focusStreak}-day focus streak — level ${progress.level} with ${progress.totalXp} XP.',
        timestamp: now,
        type: 'motivation',
      ));
    }

    final habits = _habitRepo.getAllHabits();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final incomplete = habits
        .where((h) => !h.completedDates.contains(todayKey))
        .length;

    if (incomplete > 0 && incomplete <= 3 && habits.isNotEmpty) {
      messages.add(CoachMessage(
        id: 'habits_${now.millisecondsSinceEpoch}',
        message:
            '$incomplete habit${incomplete > 1 ? 's' : ''} left today — finishing them boosts your attention score.',
        timestamp: now,
        type: 'reminder',
        actionLabel: 'View Habits',
        actionRoute: '/habits',
      ));
    }

    if (messages.length <= 1 && now.hour >= 6 && now.hour <= 10) {
      messages.add(CoachMessage(
        id: 'morning_${now.millisecondsSinceEpoch}',
        message:
            'Morning, $name — your lowest-distraction window. Great time for deep work.',
        timestamp: now,
        type: 'tip',
        actionLabel: 'Start Focus',
        actionRoute: '/focus',
      ));
    }

    if (messages.isEmpty) {
      messages.add(CoachMessage(
        id: 'tip_${now.millisecondsSinceEpoch}',
        message: _fallbackTip(name),
        timestamp: now,
        type: 'tip',
      ));
    }

    return _saveAndReturn(messages.take(6).toList());
  }

  Future<CoachMessage> respondToPrompt(String prompt) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final settings = _settingsRepo.getSettings();
    final name = settings.userName.isNotEmpty ? settings.userName : 'there';

    final screenTime = _usageRepo.getTotalScreenTime(today);
    final socialTime =
        _usageRepo.getSocialMediaTime(today, AppPackages.socialMediaApps);
    final focusTime = _focusRepo.getTotalFocusMinutes(today);
    final progress = _gamificationRepo.getProgress();

    String message;
    String type = 'tip';
    String? actionLabel;
    String? actionRoute;

    switch (prompt) {
      case 'How am I doing today?':
        if (!settings.usageStatsGranted) {
          message =
              'I need Usage Access to read your real data, $name. Enable it in Settings first.';
          type = 'reminder';
          actionLabel = 'Open Settings';
          actionRoute = '/settings';
        } else {
          message =
              'Screen: ${_fmt(screenTime)} · Focus: ${_fmt(focusTime)} · Social: ${_fmt(socialTime)} · Streak: ${progress.focusStreak} days · Level ${progress.level}.';
        }
        break;
      case 'Start a focus sprint':
        message =
            'Let\'s go — a 15-minute sprint now. You\'ve done ${_fmt(focusTime)} of focus today.';
        actionLabel = 'Start Focus';
        actionRoute = '/focus';
        break;
      case 'Show my progress':
        message =
            'Level ${progress.level} (${progress.totalXp} XP), ${progress.focusStreak}-day streak, ${_fmt(focusTime)} focus today.';
        type = 'success';
        actionLabel = 'Achievements';
        actionRoute = '/achievements';
        break;
      default:
        message = _fallbackTip(name);
    }

    final msg = CoachMessage(
      id: 'prompt_${now.millisecondsSinceEpoch}',
      message: message,
      timestamp: now,
      type: type,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
    );
    await _coachRepo.saveMessage(msg);
    return msg;
  }

  String _fmt(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _fallbackTip(String name) {
    final tips = [
      'Small focus sessions add up, $name. Start with 15 minutes.',
      'Your attention is your superpower — guard it today.',
      'Every minute away from distractions is a win.',
      'Consistency beats intensity. Show up for one focus block.',
    ];
    return tips[_random.nextInt(tips.length)];
  }

  Future<List<CoachMessage>> _saveAndReturn(List<CoachMessage> messages) async {
    for (final msg in messages) {
      await _coachRepo.saveMessage(msg);
    }
    return messages;
  }
}

class InterventionService {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final UsageRepository _usageRepo = UsageRepository();

  InterventionLevel? checkIntervention() {
    final settings = _settingsRepo.getSettings();
    final today = DateTime.now();
    final socialTime =
        _usageRepo.getSocialMediaTime(today, AppPackages.socialMediaApps);

    if (socialTime >= AppConstants.interventionStrong) {
      return InterventionLevel.strong;
    } else if (socialTime >= AppConstants.interventionChallenge) {
      return InterventionLevel.challenge;
    } else if (socialTime >= AppConstants.interventionMotivational) {
      return InterventionLevel.motivational;
    } else if (socialTime >= AppConstants.interventionGentle) {
      return InterventionLevel.gentle;
    }
    return null;
  }

  String getInterventionMessage(InterventionLevel level, int minutes) {
    switch (level) {
      case InterventionLevel.gentle:
        return 'You\'ve been scrolling for $minutes minutes. Maybe take a short break?';
      case InterventionLevel.motivational:
        return 'That\'s $minutes minutes of scrolling. Imagine what you could create instead!';
      case InterventionLevel.challenge:
        return 'Challenge time! You\'ve spent $minutes minutes on distractions. Ready for a focus sprint?';
      case InterventionLevel.strong:
        return '''You spent ${minutes ~/ 60} hour${minutes >= 120 ? 's' : ''} scrolling.

That could have been:

✓ 30 pages read
✓ 1 coding lesson
✓ 5km walk

Start Focus Mode?''';
    }
  }
}

enum InterventionLevel { gentle, motivational, challenge, strong }

class AchievementService {
  static List<Achievement> generateAchievements() {
    final achievements = <Achievement>[];
    final templates = [
      ('first_focus', 'First Focus Session', 'Complete your first focus session', '🎯', 'focus', 1, 'sessions'),
      ('first_week', 'First Week', 'Use SKROL for 7 days', '📅', 'general', 7, 'days'),
      ('streak_7', '7 Day Streak', 'Maintain a 7-day focus streak', '🔥', 'streak', 7, 'streak'),
      ('streak_30', '30 Day Streak', 'Maintain a 30-day focus streak', '💎', 'streak', 30, 'streak'),
      ('focus_100h', '100 Hours Focused', 'Accumulate 100 hours of focus time', '⏰', 'focus', 6000, 'minutes'),
      ('monk_master', 'Monk Mode Master', 'Complete 10 Monk Mode sessions', '🧘', 'monk', 10, 'monk_sessions'),
      ('productivity_champion', 'Productivity Champion', 'Reach level 25', '🏆', 'level', 25, 'level'),
      ('habit_hero', 'Habit Hero', 'Complete 100 habits', '✅', 'habits', 100, 'habits'),
      ('social_warrior', 'Social Warrior', 'Stay under social media limit for 7 days', '🛡️', 'social', 7, 'social_days'),
      ('early_bird', 'Early Bird', 'Complete a focus session before 8 AM', '🌅', 'focus', 1, 'early_sessions'),
    ];

    for (final t in templates) {
      achievements.add(Achievement(
        id: t.$1,
        title: t.$2,
        description: t.$3,
        icon: t.$4,
        category: t.$5,
        requirement: t.$6,
        requirementType: t.$7,
        xpReward: 50 + t.$6,
        rarity: t.$6 >= 30 ? 'legendary' : t.$6 >= 10 ? 'rare' : 'common',
      ));
    }

    // Generate additional achievements to reach 100+
    final categories = ['focus', 'habits', 'streak', 'social', 'monk', 'level'];
    final icons = ['⭐', '🌟', '💫', '🎖️', '🏅', '🎗️', '👑', '💪', '🚀', '📈'];
    for (int i = 0; i < 90; i++) {
      final cat = categories[i % categories.length];
      final req = (i + 1) * 5;
      achievements.add(Achievement(
        id: 'achievement_$i',
        title: _generateTitle(cat, req),
        description: _generateDescription(cat, req),
        icon: icons[i % icons.length],
        category: cat,
        requirement: req,
        requirementType: cat,
        xpReward: 25 + (i % 50),
        rarity: i % 10 == 0 ? 'legendary' : i % 5 == 0 ? 'rare' : 'common',
      ));
    }

    return achievements;
  }

  static String _generateTitle(String category, int req) {
    switch (category) {
      case 'focus':
        return '$req Focus Sessions';
      case 'habits':
        return '$req Habits Completed';
      case 'streak':
        return '$req Day Streak';
      case 'social':
        return '$req Days Under Limit';
      case 'monk':
        return '$req Monk Sessions';
      default:
        return 'Level $req Milestone';
    }
  }

  static String _generateDescription(String category, int req) {
    return 'Reach $req in ${_generateTitle(category, req).toLowerCase()}';
  }

  Future<void> seedAchievements() async {
    final existing = GamificationRepository().getAllAchievements();
    if (existing.isNotEmpty) return;

    for (final achievement in generateAchievements()) {
      await HiveService.achievementsBox.put(achievement.id, achievement);
    }
  }

  Future<List<Achievement>> checkAndUnlock() async {
    final progress = GamificationRepository().getProgress();
    final all = GamificationRepository().getAllAchievements();
    final unlocked = <Achievement>[];

    for (final achievement in all) {
      if (progress.unlockedAchievements.contains(achievement.id)) continue;

      bool shouldUnlock = false;
      switch (achievement.requirementType) {
        case 'sessions':
          shouldUnlock = progress.totalFocusSessions >= achievement.requirement;
        case 'streak':
          shouldUnlock = progress.focusStreak >= achievement.requirement;
        case 'minutes':
          shouldUnlock = progress.totalFocusMinutes >= achievement.requirement;
        case 'monk_sessions':
          shouldUnlock = progress.monkModeSessions >= achievement.requirement;
        case 'level':
          shouldUnlock = progress.level >= achievement.requirement;
        case 'habits':
          shouldUnlock = progress.totalHabitsCompleted >= achievement.requirement;
      }

      if (shouldUnlock) {
        final result =
            await GamificationRepository().unlockAchievement(achievement.id);
        unlocked.addAll(result);
      }
    }

    return unlocked;
  }
}
