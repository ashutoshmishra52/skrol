import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class UserSettings extends HiveObject {
  UserSettings({
    this.userName = 'User',
    this.onboardingComplete = false,
    this.selectedGoals = const [],
    this.distractingApps = const [],
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    this.usageStatsGranted = false,
    this.notificationGranted = false,
    this.accessibilityGranted = false,
    this.dailyScreenTimeGoalMinutes = 180,
    this.dailySocialMediaLimitMinutes = 60,
    this.dailyFocusGoalMinutes = 120,
    this.createdAt,
  });

  @HiveField(0)
  String userName;

  @HiveField(1)
  bool onboardingComplete;

  @HiveField(2)
  List<String> selectedGoals;

  @HiveField(3)
  List<String> distractingApps;

  @HiveField(4)
  String themeMode;

  @HiveField(5)
  bool notificationsEnabled;

  @HiveField(6)
  bool usageStatsGranted;

  @HiveField(7)
  bool notificationGranted;

  @HiveField(8)
  bool accessibilityGranted;

  @HiveField(9)
  int dailyScreenTimeGoalMinutes;

  @HiveField(10)
  int dailySocialMediaLimitMinutes;

  @HiveField(11)
  int dailyFocusGoalMinutes;

  @HiveField(12)
  DateTime? createdAt;

  UserSettings copyWith({
    String? userName,
    bool? onboardingComplete,
    List<String>? selectedGoals,
    List<String>? distractingApps,
    String? themeMode,
    bool? notificationsEnabled,
    bool? usageStatsGranted,
    bool? notificationGranted,
    bool? accessibilityGranted,
    int? dailyScreenTimeGoalMinutes,
    int? dailySocialMediaLimitMinutes,
    int? dailyFocusGoalMinutes,
    DateTime? createdAt,
  }) {
    return UserSettings(
      userName: userName ?? this.userName,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      selectedGoals: selectedGoals ?? List.from(this.selectedGoals),
      distractingApps: distractingApps ?? List.from(this.distractingApps),
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      usageStatsGranted: usageStatsGranted ?? this.usageStatsGranted,
      notificationGranted: notificationGranted ?? this.notificationGranted,
      accessibilityGranted: accessibilityGranted ?? this.accessibilityGranted,
      dailyScreenTimeGoalMinutes:
          dailyScreenTimeGoalMinutes ?? this.dailyScreenTimeGoalMinutes,
      dailySocialMediaLimitMinutes:
          dailySocialMediaLimitMinutes ?? this.dailySocialMediaLimitMinutes,
      dailyFocusGoalMinutes:
          dailyFocusGoalMinutes ?? this.dailyFocusGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
