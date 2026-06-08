import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/home_widget_service.dart';
import 'core/services/app_services.dart';
import 'core/platform/app_platform.dart';
import 'data/repositories/repositories.dart';
import 'data/models/habit.dart';
import 'core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0E0E12),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await HiveService.init();
  await NotificationService().init();
  if (isAndroidPlatform) {
    await HomeWidgetService.init();
  }
  await _seedDefaultData();

  runApp(
    const ProviderScope(
      child: SkrolApp(),
    ),
  );
}

Future<void> _seedDefaultData() async {
  final habitRepo = HabitRepository();
  final existing = habitRepo.getAllHabits();
  if (existing.isEmpty) {
    const uuid = Uuid();
    final icons = ['📚', '💻', '🧘', '🏃', '📝', '✍️'];
    final colors = [
      '#5B7CFF',
      '#7D5CFF',
      '#00D4AA',
      '#FF6B35',
      '#FFBE0B',
      '#5B7CFF',
    ];
    for (int i = 0; i < AppConstants.defaultHabits.length; i++) {
      await habitRepo.saveHabit(Habit(
        id: uuid.v4(),
        name: AppConstants.defaultHabits[i],
        icon: icons[i],
        color: colors[i],
        createdAt: DateTime.now(),
      ));
    }
  }

  await AchievementService().seedAchievements();
}
