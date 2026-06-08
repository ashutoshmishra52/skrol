import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/user_settings.g.dart';
import '../../data/models/app_usage.dart';
import '../../data/models/app_usage.g.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/focus_session.g.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit.g.dart';
import '../../data/models/gamification.dart';
import '../../data/models/gamification.g.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(AppUsageRecordAdapter());
    Hive.registerAdapter(DailyUsageSummaryAdapter());
    Hive.registerAdapter(FocusSessionAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(UserProgressAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(CoachMessageAdapter());

    await Future.wait([
      Hive.openBox<UserSettings>(AppConstants.hiveBoxSettings),
      Hive.openBox<AppUsageRecord>(AppConstants.hiveBoxUsage),
      Hive.openBox<FocusSession>(AppConstants.hiveBoxFocus),
      Hive.openBox<Habit>(AppConstants.hiveBoxHabits),
      Hive.openBox<UserProgress>(AppConstants.hiveBoxGamification),
      Hive.openBox<Achievement>(AppConstants.hiveBoxAchievements),
      Hive.openBox<CoachMessage>(AppConstants.hiveBoxCoach),
      Hive.openBox(AppConstants.hiveBoxInterventions),
    ]);
  }

  static Box<UserSettings> get settingsBox =>
      Hive.box<UserSettings>(AppConstants.hiveBoxSettings);

  static Box<AppUsageRecord> get usageBox =>
      Hive.box<AppUsageRecord>(AppConstants.hiveBoxUsage);

  static Box<FocusSession> get focusBox =>
      Hive.box<FocusSession>(AppConstants.hiveBoxFocus);

  static Box<Habit> get habitsBox =>
      Hive.box<Habit>(AppConstants.hiveBoxHabits);

  static Box<UserProgress> get gamificationBox =>
      Hive.box<UserProgress>(AppConstants.hiveBoxGamification);

  static Box<Achievement> get achievementsBox =>
      Hive.box<Achievement>(AppConstants.hiveBoxAchievements);

  static Box<CoachMessage> get coachBox =>
      Hive.box<CoachMessage>(AppConstants.hiveBoxCoach);

  static Box get interventionsBox =>
      Hive.box(AppConstants.hiveBoxInterventions);
}
