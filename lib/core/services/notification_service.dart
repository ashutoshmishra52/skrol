import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {}

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scrollless_channel',
      'SKROL Notifications',
      channelDescription: 'Smart wellness reminders and focus alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_launcher',
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  Future<void> scheduleStreakReminder() async {
    await showNotification(
      id: 1,
      title: 'Your streak is waiting 🔥',
      body: 'Don\'t break your focus streak today!',
    );
  }

  Future<void> scheduleGoalReminder(int minutesLeft) async {
    await showNotification(
      id: 2,
      title: 'Almost there!',
      body: 'Only $minutesLeft minutes left to hit today\'s goal.',
    );
  }

  Future<void> showInterventionNotification(String message) async {
    await showNotification(
      id: 3,
      title: '${AppConstants.coachName} says...',
      body: message,
      payload: 'intervention',
    );
  }

  Future<void> showReelWatchNotification({
    required int reelCount,
    required String appName,
  }) async {
    await showNotification(
      id: 5,
      title: 'You\'ve watched a lot of reels',
      body:
          'That\'s $reelCount reels in a row on $appName. Take a short break — your attention will thank you.',
      payload: 'reel_watch',
    );
  }

  Future<void> showAchievementNotification(String title) async {
    await showNotification(
      id: 4,
      title: 'Achievement Unlocked! 🏆',
      body: title,
    );
  }
}
