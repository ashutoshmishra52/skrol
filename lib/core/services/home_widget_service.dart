import 'package:home_widget/home_widget.dart';
import '../constants/app_constants.dart';

class HomeWidgetService {
  static const _androidWidgetName = 'ScrollLessWidget'; // native class name unchanged

  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.scrollless.widget');
    await HomeWidget.registerBackgroundCallback(_backgroundCallback);
  }

  static Future<void> updateWidget({
    required int attentionScore,
    required String focusTime,
    required int focusStreak,
    required int goalProgress,
  }) async {
    await HomeWidget.saveWidgetData<int>('attention_score', attentionScore);
    await HomeWidget.saveWidgetData<String>('focus_time', focusTime);
    await HomeWidget.saveWidgetData<int>('focus_streak', focusStreak);
    await HomeWidget.saveWidgetData<int>('goal_progress', goalProgress);
    await HomeWidget.updateWidget(
      androidName: _androidWidgetName,
      iOSName: 'SkrolWidget',
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    // Widget tap handler
  }
}
