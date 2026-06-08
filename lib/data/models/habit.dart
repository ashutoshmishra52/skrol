import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class Habit extends HiveObject {
  Habit({
    required this.id,
    required this.name,
    this.icon = '✓',
    this.color = '#5B7CFF',
    this.weeklyGoal = 5,
    this.monthlyGoal = 20,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completedDates = const [],
    this.reminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.createdAt,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  String color;

  @HiveField(4)
  int weeklyGoal;

  @HiveField(5)
  int monthlyGoal;

  @HiveField(6)
  int currentStreak;

  @HiveField(7)
  int longestStreak;

  @HiveField(8)
  List<String> completedDates;

  @HiveField(9)
  bool reminderEnabled;

  @HiveField(10)
  int reminderHour;

  @HiveField(11)
  int reminderMinute;

  @HiveField(12)
  DateTime? createdAt;

  bool isCompletedToday(String todayKey) => completedDates.contains(todayKey);

  int getWeeklyCompletions(DateTime weekStart) {
    return completedDates.where((d) {
      final parts = d.split('-');
      if (parts.length != 3) return false;
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return !date.isBefore(weekStart) &&
          date.isBefore(weekStart.add(const Duration(days: 7)));
    }).length;
  }
}
