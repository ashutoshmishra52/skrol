import 'package:hive/hive.dart';

enum FocusModeType {
  pomodoro,
  deepWork,
  coding,
  study,
  reading,
  exam,
  monk,
}

@HiveType(typeId: 3)
class FocusSession extends HiveObject {
  FocusSession({
    required this.id,
    required this.mode,
    required this.startTime,
    this.endTime,
    this.plannedDurationMinutes = 25,
    this.actualDurationMinutes = 0,
    this.completed = false,
    this.notes = '',
    this.xpEarned = 0,
    this.isMonkMode = false,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String mode;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  int plannedDurationMinutes;

  @HiveField(5)
  int actualDurationMinutes;

  @HiveField(6)
  bool completed;

  @HiveField(7)
  String notes;

  @HiveField(8)
  int xpEarned;

  @HiveField(9)
  bool isMonkMode;

  FocusModeType get modeType => FocusModeType.values.firstWhere(
        (e) => e.name == mode,
        orElse: () => FocusModeType.pomodoro,
      );

  String get modeDisplayName {
    switch (modeType) {
      case FocusModeType.pomodoro:
        return 'Pomodoro';
      case FocusModeType.deepWork:
        return 'Deep Work';
      case FocusModeType.coding:
        return 'Coding Session';
      case FocusModeType.study:
        return 'Study Session';
      case FocusModeType.reading:
        return 'Reading Session';
      case FocusModeType.exam:
        return 'Exam Mode';
      case FocusModeType.monk:
        return 'Monk Mode';
    }
  }
}
