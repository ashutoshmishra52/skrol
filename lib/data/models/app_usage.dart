import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class AppUsageRecord extends HiveObject {
  AppUsageRecord({
    required this.packageName,
    required this.appName,
    required this.date,
    required this.usageMinutes,
    this.category = 'Other',
    this.isDistraction = false,
  });

  @HiveField(0)
  String packageName;

  @HiveField(1)
  String appName;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int usageMinutes;

  @HiveField(4)
  String category;

  @HiveField(5)
  bool isDistraction;

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

@HiveType(typeId: 2)
class DailyUsageSummary extends HiveObject {
  DailyUsageSummary({
    required this.date,
    this.totalScreenTimeMinutes = 0,
    this.socialMediaMinutes = 0,
    this.focusMinutes = 0,
    this.appSwitchCount = 0,
    this.attentionScore = 50,
    this.dopamineScore = 50,
    this.reelsCount = 0,
    this.shortsCount = 0,
  });

  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int totalScreenTimeMinutes;

  @HiveField(2)
  int socialMediaMinutes;

  @HiveField(3)
  int focusMinutes;

  @HiveField(4)
  int appSwitchCount;

  @HiveField(5)
  int attentionScore;

  @HiveField(6)
  int dopamineScore;

  @HiveField(7)
  int reelsCount;

  @HiveField(8)
  int shortsCount;

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class DailyScrollRecord {
  const DailyScrollRecord({
    required this.dateKey,
    required this.reels,
    required this.shorts,
    this.reelsWatchMs = 0,
    this.shortsWatchMs = 0,
  });

  final String dateKey;
  final int reels;
  final int shorts;
  final int reelsWatchMs;
  final int shortsWatchMs;

  int get totalScrolls => reels + shorts;

  factory DailyScrollRecord.fromMap(Map<Object?, Object?> map) {
    return DailyScrollRecord(
      dateKey: map['date']?.toString() ?? '',
      reels: (map['reels'] as num?)?.toInt() ?? 0,
      shorts: (map['shorts'] as num?)?.toInt() ?? 0,
      reelsWatchMs: (map['reelsWatchMs'] as num?)?.toInt() ?? 0,
      shortsWatchMs: (map['shortsWatchMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class SocialMediaBreakdown {
  const SocialMediaBreakdown({
    this.instagramMinutes = 0,
    this.youtubeMinutes = 0,
    this.facebookMinutes = 0,
    this.xMinutes = 0,
    this.snapchatMinutes = 0,
    this.otherMinutes = 0,
    this.totalMinutes = 0,
  });

  final int instagramMinutes;
  final int youtubeMinutes;
  final int facebookMinutes;
  final int xMinutes;
  final int snapchatMinutes;
  final int otherMinutes;
  final int totalMinutes;

  static const empty = SocialMediaBreakdown();

  factory SocialMediaBreakdown.fromMap(Map<Object?, Object?> map) {
    return SocialMediaBreakdown(
      instagramMinutes: (map['instagram'] as num?)?.toInt() ?? 0,
      youtubeMinutes: (map['youtube'] as num?)?.toInt() ?? 0,
      facebookMinutes: (map['facebook'] as num?)?.toInt() ?? 0,
      xMinutes: (map['x'] as num?)?.toInt() ?? 0,
      snapchatMinutes: (map['snapchat'] as num?)?.toInt() ?? 0,
      otherMinutes: (map['other'] as num?)?.toInt() ?? 0,
      totalMinutes: (map['total'] as num?)?.toInt() ?? 0,
    );
  }
}
