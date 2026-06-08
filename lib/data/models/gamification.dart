import 'package:hive/hive.dart';

@HiveType(typeId: 5)
class UserProgress extends HiveObject {
  UserProgress({
    this.totalXp = 0,
    this.level = 1,
    this.focusStreak = 0,
    this.longestFocusStreak = 0,
    this.totalFocusMinutes = 0,
    this.totalHabitsCompleted = 0,
    this.totalFocusSessions = 0,
    this.monkModeSessions = 0,
    this.lastFocusDate,
    this.unlockedAchievements = const [],
  });

  @HiveField(0)
  int totalXp;

  @HiveField(1)
  int level;

  @HiveField(2)
  int focusStreak;

  @HiveField(3)
  int longestFocusStreak;

  @HiveField(4)
  int totalFocusMinutes;

  @HiveField(5)
  int totalHabitsCompleted;

  @HiveField(6)
  int totalFocusSessions;

  @HiveField(7)
  int monkModeSessions;

  @HiveField(8)
  DateTime? lastFocusDate;

  @HiveField(9)
  List<String> unlockedAchievements;

  int get xpForNextLevel => level * 100;
  int get xpInCurrentLevel => totalXp - _xpForLevel(level);
  double get levelProgress =>
      xpInCurrentLevel / xpForNextLevel.clamp(1, 999999);

  static int _xpForLevel(int level) {
    int xp = 0;
    for (int i = 1; i < level; i++) {
      xp += i * 100;
    }
    return xp;
  }
}

@HiveType(typeId: 6)
class Achievement extends HiveObject {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.category = 'general',
    this.xpReward = 50,
    this.requirement = 1,
    this.requirementType = 'sessions',
    this.rarity = 'common',
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String icon;

  @HiveField(4)
  String category;

  @HiveField(5)
  int xpReward;

  @HiveField(6)
  int requirement;

  @HiveField(7)
  String requirementType;

  @HiveField(8)
  String rarity;
}

@HiveType(typeId: 7)
class CoachMessage extends HiveObject {
  CoachMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    this.type = 'info',
    this.actionLabel,
    this.actionRoute,
    this.read = false,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String message;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  String type;

  @HiveField(4)
  String? actionLabel;

  @HiveField(5)
  String? actionRoute;

  @HiveField(6)
  bool read;
}
