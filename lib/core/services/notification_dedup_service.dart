import 'hive_service.dart';
import 'app_services.dart';

class NotificationDedupService {
  static const _prefix = 'notified_';

  static bool shouldSendIntervention(InterventionLevel level) {
    final todayKey = _todayKey();
    final key = '${_prefix}intervention_${level.name}_$todayKey';
    if (HiveService.interventionsBox.get(key) == true) return false;
    HiveService.interventionsBox.put(key, true);
    return true;
  }

  static bool shouldSendReelThreshold() {
    final todayKey = _todayKey();
    final key = '${_prefix}reel_threshold_$todayKey';
    if (HiveService.interventionsBox.get(key) == true) return false;
    HiveService.interventionsBox.put(key, true);
    return true;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
