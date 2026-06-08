class AppConstants {
  AppConstants._();

  static const String appName = 'SKROL';
  static const String tagline = 'Track Less. Live More.';
  static const String website = 'https://skrol.in';
  static const String developer = 'Ashutosh Mishra';
  static const String coachName = 'Aetheris';
  static const String coachTagline = 'Your data-driven focus companion';

  static const String hiveBoxSettings = 'settings';
  static const String hiveBoxUsage = 'usage';
  static const String hiveBoxFocus = 'focus';
  static const String hiveBoxHabits = 'habits';
  static const String hiveBoxGamification = 'gamification';
  static const String hiveBoxAchievements = 'achievements';
  static const String hiveBoxCoach = 'coach';
  static const String hiveBoxInterventions = 'interventions';

  // XP Rewards
  static const int xpFocusSession = 25;
  static const int xpHabitComplete = 10;
  static const int xpUnderSocialLimit = 20;
  static const int xpSevenDayStreak = 100;
  static const int xpMonkModeBonus = 50;

  // Reel-watch intervention
  static const int reelWatchThreshold = 20;
  static const int secondsPerReelEstimate = 15;
  static const int reelWatchPollSeconds = 20;

  // Intervention thresholds (minutes)
  static const int interventionGentle = 15;
  static const int interventionMotivational = 30;
  static const int interventionChallenge = 45;
  static const int interventionStrong = 60;

  // Level thresholds
  static const Map<int, String> levelTitles = {
    1: 'Beginner',
    10: 'Focus Explorer',
    25: 'Productivity Warrior',
    50: 'Deep Work Master',
    100: 'SKROL Legend',
  };

  static const List<String> defaultGoals = [
    'Coding',
    'Study',
    'Reading',
    'Business',
    'Exercise',
    'Meditation',
    'Personal Growth',
  ];

  static const List<String> defaultDistractingApps = [
    'com.instagram.android',
    'com.google.android.youtube',
    'com.linkedin.android',
    'com.twitter.android',
    'com.facebook.katana',
  ];

  static const List<String> defaultHabits = [
    'Reading',
    'Coding',
    'Meditation',
    'Exercise',
    'Study',
    'Journaling',
  ];
}
